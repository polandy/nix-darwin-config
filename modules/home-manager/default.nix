{ config, pkgs, lib, sops-nix, mac-app-util, ... }:

{
  # These are nix-darwin options that tell the macOS system builder how to integrate with Home Manager.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  # Include sops-nix home-manager module for all hosts
  home-manager.sharedModules = [
    sops-nix.homeManagerModules.sops
    # Aliases for .app bundles coming from home.packages (Alacritty, AeroSpace).
    # The counterpart for environment.systemPackages lives in lib/default.nix.
    mac-app-util.homeManagerModules.default
    ./generic # fish + git for all hosts
  ];
}
