{ config, pkgs, lib, self, home-manager, sops-nix, ... }:

{
  imports = [
    ../../modules/macos
    ../../modules/macos/leisure
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
  ];

  home-manager.users.andy = import ./home.nix;
}
