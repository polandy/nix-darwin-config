{
  description = "Andys nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, sops-nix, ... }:
    let
      lib = nixpkgs.lib;
      darwinSystem = "aarch64-darwin";
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # $ darwin-rebuild build --flake .#ambp
      darwinConfigurations = {
        "ambp" = nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          # Pass 'self' to modules
          specialArgs = { inherit self lib home-manager sops-nix; };
          modules = [
            ./hosts/ambp
            {
              # Disable nix-darwin's management of the Nix daemon and nix.conf
              # because we use the Determinate Systems Nix installer.
              # https://github.com/DeterminateSystems/nix-installer
              nix.enable = false;
            }
          ];
        };
        "amba" = nix-darwin.lib.darwinSystem {
          system = darwinSystem;
          # Pass 'self' to modules
          specialArgs = { inherit self lib home-manager sops-nix; };
          modules = [
            ./hosts/amba

            {
              # Disable nix-darwin's management of the Nix daemon and nix.conf
              # because we use the Determinate Systems Nix installer.
              # https://github.com/DeterminateSystems/nix-installer
              nix.enable = false;
            }
          ];
        };
      };

      # Standalone home-manager for Linux hosts
      homeConfigurations = {
        "andy@x1" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          extraSpecialArgs = { inherit sops-nix; };
          modules = [
            ./hosts/x1/home.nix
            sops-nix.homeManagerModules.sops
          ];
        };
        "andy@coolermaster" = home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          extraSpecialArgs = { inherit sops-nix; };
          modules = [
            ./hosts/coolermaster/home.nix
            sops-nix.homeManagerModules.sops
          ];
        };
      };

      formatter = {
        ${darwinSystem} = (pkgsFor darwinSystem).nixpkgs-fmt;
        "x86_64-linux" = (pkgsFor "x86_64-linux").nixpkgs-fmt;
      };
    };
}
