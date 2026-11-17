{ config, pkgs, lib, self, home-manager, ... }:

{
  imports = [
    ../../modules/macos
    ../../modules/macos/desktop
    ../../modules/macos/leisure
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
    ./homebrew.nix
  ];

  # Must match the flake config name (`just switch` uses hostname -s)
  networking.hostName = "amba";
  networking.localHostName = "amba";

  home-manager.users.andy = import ./home.nix;
}
