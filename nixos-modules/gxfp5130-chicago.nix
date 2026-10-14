{ pkgs, ... }:
let
  project = (import ../lib/projects.nix { inherit pkgs; }).gxfp5130-chicago;
in
{
  imports = [ (project.src + "/nix/module.nix") ];
}
