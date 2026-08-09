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
    # Legt fuer .app-Bundles aus dem Nix-Store echte macOS-Aliase statt Symlinks an,
    # damit Spotlight und Dock sie finden. Ohne das sind nixpkgs-GUI-Apps praktisch
    # nur ueber den Finder erreichbar.
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
