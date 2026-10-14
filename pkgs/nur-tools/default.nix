{ lib, writeShellApplication, nix }:
let
  settings = import ../../lib/cache-config.nix;
  withCaches = writeShellApplication {
    name = "nur-with-caches";
    meta = { license = lib.licenses.mit; homepage = "https://github.com/lihaoze123/nur-packages"; };
    runtimeInputs = [ nix ];
    text = ''
      if [[ $# -lt 2 ]]; then
        echo "Usage: nur-with-caches GROUP[,GROUP...] COMMAND [ARGS...]" >&2
        echo "       nur-with-caches GROUP[,GROUP...] --print-config" >&2
        exit 2
      fi
      groups=$1
      shift
      urls=(${lib.escapeShellArgs settings.base})
      keys=()
      IFS=',' read -r -a selected <<< "$groups"
      for group in "''${selected[@]}"; do
        case "$group" in
          base) ;;
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (group: caches: ''
            ${group})
              urls+=(${lib.escapeShellArgs (map (name: settings.caches.${name}.url) caches)})
              keys+=(${lib.escapeShellArgs (map (name: settings.caches.${name}.key) caches)})
              ;;
          '') settings.groups)}
          *) echo "Unknown cache group: $group" >&2; exit 2 ;;
        esac
      done
      cache_config="substituters = ''${urls[*]}"
      cache_config+=$'\n'"extra-trusted-public-keys = ''${keys[*]}"
      if [[ $1 == --print-config ]]; then
        printf '%s\n' "$cache_config"
        exit 0
      fi
      export NIX_CONFIG="''${NIX_CONFIG:-}"$'\n'"$cache_config"
      exec "$@"
    '';
  };
  install = writeShellApplication {
    name = "nur-install";
    meta = { license = lib.licenses.mit; homepage = "https://github.com/lihaoze123/nur-packages"; };
    runtimeInputs = [ nix withCaches ];
    text = ''
      private=false
      if [[ ''${1:-} == --private ]]; then private=true; shift; fi
      if [[ $# -eq 0 ]]; then
        echo "Usage: nur-install [--private] PACKAGE..." >&2
        exit 2
      fi
      groups=base
      if $private; then groups+=,nur; fi
      installables=()
      for package in "$@"; do
        case "$package" in
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (package: caches: ''
            ${package}) groups+=${lib.escapeShellArg (lib.concatMapStrings (cache: "," + cache) caches)} ;;
          '') settings.packages)}
          *) echo "Unknown NUR package: $package" >&2; exit 2 ;;
        esac
        installables+=("github:lihaoze123/nur-packages#$package")
      done
      exec nur-with-caches "$groups" nix profile add "''${installables[@]}"
    '';
  };
in
{
  inherit withCaches install;
}
