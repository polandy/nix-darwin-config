{ config, pkgs, lib, sops-nix, ... }:

{
  # These are nix-darwin options that tell the macOS system builder how to integrate with Home Manager.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  # Include sops-nix home-manager module for all hosts
  home-manager.sharedModules = [
    sops-nix.homeManagerModules.sops
    ./generic   # fish + git for all hosts
  ];
}
