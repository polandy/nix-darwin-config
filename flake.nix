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
    system = "aarch64-darwin";
    lib = nixpkgs.lib;
  in
  {
    # $ darwin-rebuild build --flake .#ambp
    darwinConfigurations = {
      "ambp" = nix-darwin.lib.darwinSystem {
        inherit system;
        # Pass 'self' to modules
        specialArgs = { inherit self lib home-manager; };
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
        inherit system;
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

    formatter.${system} = nixpkgs.legacyPackages.${system}.nixpkgs-fmt;
  };
}
