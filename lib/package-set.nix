{ pkgs, packageRoot ? ../pkgs }:

let
  inherit (pkgs) lib;
  directories = lib.filterAttrs
    (name: type: type == "directory" && builtins.pathExists (packageRoot + "/${name}/default.nix"))
    (builtins.readDir packageRoot);
  scope = lib.makeScope pkgs.newScope (self: lib.mapAttrs
    (name: _: self.callPackage (packageRoot + "/${name}/default.nix") { })
    directories);
in
lib.getAttrs (builtins.attrNames directories) scope
