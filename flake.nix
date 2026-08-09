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
    # Creates real macOS aliases instead of symlinks for .app bundles from the Nix
    # store, so Spotlight and the Dock can find them. Without it, nixpkgs GUI apps
    # are practically only reachable through Finder.
    mac-app-util.url = "github:hraban/mac-app-util";
    mac-app-util.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, home-manager, sops-nix, ... }:
    let
      myLib = import ./lib { inherit inputs; };
      inherit (myLib) mkDarwin mkHome;
      darwinSystem = "aarch64-darwin";
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # $ darwin-rebuild build --flake .#ambp
      darwinConfigurations = {
        "ambp" = mkDarwin { host = "ambp"; };
        "amba" = mkDarwin { host = "amba"; };
      };

      # Standalone home-manager for Linux hosts
      homeConfigurations = {
        "andy@x1" = mkHome { host = "x1"; };
        "andy@coolermaster" = mkHome { host = "coolermaster"; };
      };

      formatter = {
        ${darwinSystem} = (pkgsFor darwinSystem).nixpkgs-fmt;
        "x86_64-linux" = (pkgsFor "x86_64-linux").nixpkgs-fmt;
      };
    };
}
