{ config, pkgs, lib, self, home-manager, ... }:

{
  imports = [
    ../../modules/macos
    ../../modules/macos/desktop
    ../../modules/macos/devops
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
    ./homebrew.nix
    ./mas-apps.nix
  ];

  # Must match the flake config name (`just switch` uses hostname -s)
  networking.hostName = "ambp";
  networking.localHostName = "ambp";

  home-manager.users.andy = import ./home.nix;
}
