#!/usr/bin/env python3
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
import urllib.error

SCRIPTS = Path(__file__).resolve().parents[2] / "scripts"
sys.path.insert(0, str(SCRIPTS))
import cache_metadata


def load_script(name):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f"{name}.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


planner = load_script("ci-plan")
OUT = "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-example"
DEV = "/nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-example-dev"


class CachePlanTests(unittest.TestCase):
    def test_upstream_hit_still_needs_private_upload(self):
        result = planner.make_plan([{"attr": "example", "outputs": {"out": OUT}, "cacheStatus": "cached"}], lambda _: None)
        self.assertEqual(result["matrix"]["include"][0]["attr"], "example")

    def test_every_output_must_be_in_private_cache(self):
        row = {"attr": "example", "outputs": {"out": OUT, "dev": DEV}}
        result = planner.make_plan([row], lambda path: {} if path == OUT else None)
        self.assertFalse(result["matrix"]["include"][0]["skip"])
        self.assertEqual(set(result["paths"]), {OUT, DEV})

    def test_cache_hits_produce_valid_empty_matrix(self):
        result = planner.make_plan([{"attr": "example", "outputs": {"out": OUT}}], lambda _: {})
        self.assertEqual(result["cached"], ["example"])
        self.assertTrue(result["matrix"]["include"][0]["skip"])

    def test_one_evaluation_error_preserves_other_jobs(self):
        result = planner.make_plan([{"attr": "broken", "error": "IFD failed"}, {"attr": "working", "outputs": {"out": OUT}}])
        self.assertEqual(result["matrix"]["include"][0]["attr"], "working")
        self.assertEqual(result["errors"][0]["attr"], "broken")

    def test_unknown_output_is_an_error_not_a_cache_hit(self):
        result = planner.make_plan([{"attr": "dynamic", "outputs": {"out": None, "dev": DEV}}])
        self.assertEqual(result["errors"][0]["attr"], "dynamic")
        self.assertEqual(result["paths"], [])


class MetadataTests(unittest.TestCase):
    def setUp(self):
        self.local = {"narHash": "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=", "narSize": 32, "references": [OUT, DEV]}
        self.remote = {"StorePath": OUT, "NarHash": "sha256:" + "00" * 32, "NarSize": "32", "References": f"{Path(DEV).name} {Path(OUT).name}"}

    def test_different_hash_formats_and_reference_order_are_accepted(self):
        cache_metadata.validate_metadata(OUT, self.local, self.remote)

    def test_missing_output_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Missing"):
            cache_metadata.validate_metadata(OUT, self.local, None)

    def test_changed_content_and_missing_dependency_are_rejected(self):
        for key, value in [("NarHash", "sha256:" + "ff" * 32), ("NarSize", "64"), ("References", Path(OUT).name)]:
            with self.subTest(key=key), self.assertRaisesRegex(ValueError, "differs"):
                cache_metadata.validate_metadata(OUT, self.local, {**self.remote, key: value})

    def test_authentication_failure_is_not_treated_as_a_miss(self):
        error = urllib.error.HTTPError("https://cache.invalid", 401, "Unauthorized", {}, None)
        with patch("urllib.request.urlopen", side_effect=error), self.assertRaises(urllib.error.HTTPError):
            cache_metadata.fetch_metadata(OUT, "test-only-token")

    def test_404_is_a_cache_miss(self):
        error = urllib.error.HTTPError("https://cache.invalid", 404, "Not Found", {}, None)
        with patch("urllib.request.urlopen", side_effect=error):
            self.assertIsNone(cache_metadata.fetch_metadata(OUT, "test-only-token"))


if __name__ == "__main__":
    unittest.main()
