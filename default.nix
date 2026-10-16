{ pkgs ? import <nixpkgs> { } }:
let
  tools = pkgs.callPackage ./pkgs/nur-tools { };
in
{
  lib = import ./lib { inherit pkgs; };
  nixosModules = import ./nixos-modules;
  overlays = import ./overlays;

  cloudflare-cli = pkgs.callPackage ./pkgs/cloudflare-cli { };
  dbx = pkgs.callPackage ./pkgs/dbx { };
  honk = pkgs.callPackage ./pkgs/honk { };
  try = pkgs.callPackage ./pkgs/try { };
  vscode = pkgs.callPackage ./pkgs/vscode { };
  vtype-linux = pkgs.callPackage ./pkgs/vtype-linux { };
  wxc = pkgs.callPackage ./pkgs/wxc { };

  nur-with-caches = tools.withCaches;
  nur-install = tools.install;
}
