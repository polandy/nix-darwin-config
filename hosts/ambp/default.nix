{ config, pkgs, lib, self, home-manager, ... }:

{
  imports = [
    ../../modules/macos
    ../../modules/macos/devops
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
  ];

  home-manager.users.andy = import ./home.nix;
}
