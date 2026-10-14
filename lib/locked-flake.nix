# Evaluate pinned upstream flakes using derivation fetchers. Unlike getFlake,
# this also works in NUR's restricted evaluator and performs no builtin fetches.
{ pkgs }:
{ src, sourceInfo, lockFile }:
let
  inherit (pkgs) lib;
  lock = lib.importJSON lockFile;
  dates = lib.importJSON ../sources/dates.json;
  fetchDrv = info:
    if info.type == "github" then pkgs.fetchFromGitHub {
      inherit (info) owner repo rev;
      hash = info.narHash;
      name = "source";
    } else if info.type == "tarball" then pkgs.fetchzip {
      inherit (info) url;
      hash = info.narHash;
      name = "source";
      nativeBuildInputs = [ pkgs.zstd ];
    } else throw "Unsupported pinned flake source: ${info.type}";
  # Match fetchTree's source-path context, not a fetch derivation dependency.
  # The verified hash keeps this permitted in pure/restricted evaluation.
  fetch = info:
    let fetched = fetchDrv info;
    in builtins.seq (builtins.readDir fetched)
      (builtins.path { path = fetched; sha256 = info.narHash; name = "source"; });
  resolve = ref:
    if builtins.isList ref then lib.foldl'
      (node: input: resolve lock.nodes.${node}.inputs.${input}) lock.root ref
    else ref;
  nodes = lib.mapAttrs
    (name: node:
      let
        info = if name == lock.root then sourceInfo else node.locked;
        path = if name == lock.root then src else fetch info;
        source = info // {
          outPath = path;
          lastModifiedDate = dates.${toString (info.lastModified or 0)} or "19700101000000";
        } // lib.optionalAttrs (info ? rev) {
          shortRev = builtins.substring 0 7 info.rev;
        };
        inputs = lib.mapAttrs (_: ref: nodes.${resolve ref}) (node.inputs or { });
        outputs = (import (path + "/flake.nix")).outputs (inputs // { self = result; });
        result = source // outputs // { inherit inputs; sourceInfo = source; };
      in
      if node.flake or true then result else source)
    lock.nodes;
in
nodes.${lock.root}
