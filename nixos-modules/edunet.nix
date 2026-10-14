{ pkgs, ... }:
{
  imports = [ (import ../lib/projects.nix { inherit pkgs; }).edunet.nixosModules.default ];
}
