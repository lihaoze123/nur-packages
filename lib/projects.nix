{ pkgs }:
let
  specs = pkgs.lib.importJSON ../sources/projects.json;
  sourceDrv = name: pkgs.fetchFromGitHub {
    inherit (specs.${name}) owner repo rev;
    hash = specs.${name}.narHash;
    name = "source";
  };
  source = name: builtins.path { path = sourceDrv name; sha256 = specs.${name}.narHash; name = "source"; };
  locked = name: import ./locked-flake.nix { inherit pkgs; } {
    src = source name;
    sourceInfo = specs.${name};
    lockFile = ../sources + "/${name}.lock";
  };
in
{
  dms-xhup = {
    src = source "dms-xhup";
    package = pkgs.callPackage (source "dms-xhup" + "/nix/package.nix") { };
  };
  computer-use = locked "niri-computer-use";
  edunet = locked "hhu-edunet-cli";
  gxfp5130-chicago = {
    src = source "gxfp5130-chicago";
    packages = import (source "gxfp5130-chicago" + "/nix/packages.nix") { inherit pkgs; };
  };
}
