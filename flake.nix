{
  description = "lihaoze123's NUR packages";

  inputs.nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.zst";

  outputs = { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" ];
    in
    {
      legacyPackages = forAllSystems (system: import ./default.nix {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      });
      packages = forAllSystems (system: nixpkgs.lib.filterAttrs
        (_: value: nixpkgs.lib.isDerivation value)
        self.legacyPackages.${system});
      nixosModules = import ./nixos-modules;
      overlays = import ./overlays;
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
