{ pkgs }:
let
  projects = import ../lib/projects.nix { inherit pkgs; };
in
{
  computer-use = projects.computer-use.nixosModules.default;
  edunet = projects.edunet.nixosModules.default;
  gxfp5130-chicago = projects.gxfp5130-chicago.src + "/nix/module.nix";
}
