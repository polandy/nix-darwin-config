{ config, pkgs, lib, self, home-manager, sops-nix, ... }:

{
  imports = [
    ../../modules/base
    ../../modules/macos
    ../../modules/leisure
    home-manager.darwinModules.home-manager
  ];

  # These are nix-darwin options that tell the macOS system builder how to integrate with Home Manager.
  # They cannot be placed in modules/home-manager/home.nix because that file is evaluated purely within the
  # Home Manager context, which doesn't know what home-manager.useGlobalPkgs means.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";
  home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
  home-manager.users.andy = import ./home.nix;
}
