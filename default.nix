{ pkgs ? import <nixpkgs> { } }:

{
  lib = import ./lib { inherit pkgs; };
  nixosModules = import ./nixos-modules;
  overlays = import ./overlays;

  dbx = pkgs.callPackage ./pkgs/dbx { };
  honk = pkgs.callPackage ./pkgs/honk { };
  try = pkgs.callPackage ./pkgs/try { };
  vscode = pkgs.callPackage ./pkgs/vscode { };
  vtype-linux = pkgs.callPackage ./pkgs/vtype-linux { };
  wxc = pkgs.callPackage ./pkgs/wxc { };
}
