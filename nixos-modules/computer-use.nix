{ pkgs, ... }:
{
  imports = [ (import ../lib/projects.nix { inherit pkgs; }).computer-use.nixosModules.default ];
}
