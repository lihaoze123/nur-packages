#!/usr/bin/env bash
set -euo pipefail
umask 077
if [[ $# != 1 ]]; then echo "Usage: cache-r2.sh OUTPUT_PATHS_FILE" >&2; exit 2; fi
: "${R2_CACHE_STORE:?}"
: "${R2_CACHE_CREDENTIALS:?}"
: "${NIX_CACHE_SIGNING_KEY:?}"
cache_temp=$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/nur-r2.XXXXXX")
trap 'rm -f "$cache_temp/credentials" "$cache_temp/signing-key"' EXIT
printf '%s\n' "$R2_CACHE_CREDENTIALS" > "$cache_temp/credentials"
printf '%s\n' "$NIX_CACHE_SIGNING_KEY" > "$cache_temp/signing-key"
export AWS_SHARED_CREDENTIALS_FILE="$cache_temp/credentials"
unset R2_CACHE_CREDENTIALS NIX_CACHE_SIGNING_KEY
mapfile -t paths < "$1"
if [[ ${#paths[@]} == 0 ]]; then echo "No outputs to cache."; exit 0; fi
nix copy --to "file://$cache_temp/stage?compression=zstd&compression-level=3&secret-key=$cache_temp/signing-key" "${paths[@]}"
export RCLONE_S3_PROVIDER=Cloudflare
export RCLONE_S3_ENV_AUTH=true
export RCLONE_S3_PROFILE=r2-cache
export RCLONE_S3_REGION=auto
export RCLONE_S3_NO_CHECK_BUCKET=true
export RCLONE_S3_ENDPOINT="https://6ed1b3dcdc0ddb8c496ad7de884c55cc.r2.cloudflarestorage.com"
rclone copy "$cache_temp/stage/nar" :s3:nix-cache/nar --checksum --s3-upload-cutoff 16M --s3-chunk-size 16M --s3-upload-concurrency 4
rclone copy "$cache_temp/stage" :s3:nix-cache --exclude '/nar/**' --checksum
# NAR objects are immutable. narinfo may legitimately change its Deriver or
# collect additional signatures when a shared cache already contains a path.
rclone check "$cache_temp/stage/nar" :s3:nix-cache/nar --one-way
nix path-info --recursive --json "${paths[@]}" > "$cache_temp/local-info.json"
nix path-info --store "$R2_CACHE_STORE" --recursive --json "${paths[@]}" > "$cache_temp/remote-info.json"
jq -e --slurpfile remote "$cache_temp/remote-info.json" '
  def index: if type == "array" then map({key: .path, value: .}) | from_entries else . end;
  ($remote[0] | index) as $r | index | to_entries |
  all(. as $p | $r[$p.key].narHash == $p.value.narHash and
    ($r[$p.key].references | sort) == ($p.value.references | sort))
' "$cache_temp/local-info.json"
nix store verify --store "$R2_CACHE_STORE" --recursive --no-contents \
  --option extra-trusted-public-keys 'r2-fonts-1:WlP+O4M04sA1u8qsLINKBmzg2YUHWJGQQRi3dbqDJaA=' \
  --option narinfo-cache-negative-ttl 0 --refresh "${paths[@]}"
echo "Published and verified signed runtime closures in the existing private R2 cache."
