{ pkgs ? import <nixpkgs> { } }:
let
  projects = import ./lib/projects.nix { inherit pkgs; };
  tools = pkgs.callPackage ./pkgs/nur-tools { };
  system = pkgs.stdenv.hostPlatform.system;
in
{
  lib = import ./lib { inherit pkgs; };
  nixosModules = import ./nixos-modules { inherit pkgs; };
  overlays = import ./overlays;

  dbx = pkgs.callPackage ./pkgs/dbx { };
  honk = pkgs.callPackage ./pkgs/honk { };
  try = pkgs.callPackage ./pkgs/try { };
  vscode = pkgs.callPackage ./pkgs/vscode { };
  vtype-linux = pkgs.callPackage ./pkgs/vtype-linux { };
  wxc = pkgs.callPackage ./pkgs/wxc { };

  dms-xhup = projects.dms-xhup.package.overrideAttrs (old: {
    meta = old.meta // { homepage = "https://github.com/lihaoze123/dms-xhup"; };
  });
  edunet = projects.edunet.packages.${system}.edunet.overrideAttrs (old: {
    meta = old.meta // { homepage = "https://github.com/lihaoze123/hhu-edunet-cli"; };
  });
  codex-desktop = projects.computer-use.packages.${system}.codex-desktop.overrideAttrs (old: {
    meta = old.meta // { sourceProvenance = [ pkgs.lib.sourceTypes.binaryNativeCode ]; };
  });
  codex-computer-use = projects.computer-use.packages.${system}.codex-computer-use.overrideAttrs (old: {
    meta = (old.meta or { }) // {
      description = "MCP launcher for Codex Computer Use on niri";
      homepage = "https://github.com/lihaoze123/niri-computer-use";
      license = pkgs.lib.licenses.mit;
      mainProgram = "codex-computer-use";
      platforms = [ "x86_64-linux" ];
    };
  });
  codex-computer-use-niri = projects.computer-use.packages.${system}.codex-computer-use-niri.overrideAttrs (old: {
    meta = (old.meta or { }) // {
      description = "Native Codex Computer Use backend patched for niri";
      homepage = "https://github.com/lihaoze123/niri-computer-use";
      license = pkgs.lib.licenses.mit;
      mainProgram = "codex-computer-use-linux";
      platforms = [ "x86_64-linux" ];
    };
  });
  inherit (projects.computer-use.packages.${system}) niri-patched;
  gxfp5130-fprintd = projects.gxfp5130-chicago.packages.fprintd.overrideAttrs (old: {
    meta = old.meta // { maintainers = [ ]; };
  });
  gxfp5130-libfprint = projects.gxfp5130-chicago.packages.libfprint;
  gxfp5130-tools = projects.gxfp5130-chicago.packages.tools.overrideAttrs (old: {
    meta = (old.meta or { }) // {
      description = "Native ChicagoHS fingerprint enrollment and verification tools";
      homepage = "https://github.com/lihaoze123/gxfp5130-chicago";
      license = pkgs.lib.licenses.mit;
      mainProgram = "gxfp-chicago-verify";
      platforms = [ "x86_64-linux" ];
    };
  });
  nur-with-caches = tools.withCaches;
  nur-install = tools.install;
}
