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
      # Resolve upstream module imports before NixOS computes its own pkgs.
      nixosModules = self.legacyPackages.x86_64-linux.nixosModules;
      overlays = import ./overlays;
      lib.cacheConfig = import ./lib/cache-config.nix;
      apps = forAllSystems (system: {
        install = { type = "app"; program = "${self.packages.${system}.nur-install}/bin/nur-install"; meta.description = "Install NUR packages with the applicable project caches"; };
        with-caches = { type = "app"; program = "${self.packages.${system}.nur-with-caches}/bin/nur-with-caches"; meta.description = "Run a Nix command with explicitly selected caches"; };
      });
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };
}
