{ config, pkgs, lib, self, home-manager, sops-nix, ... }:

{
  imports = [
    ../../modules/macos
    ../../modules/macos/devops
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
  ];

  home-manager.sharedModules = [ sops-nix.homeManagerModules.sops ];
  home-manager.users.andy = import ./home.nix;
}
