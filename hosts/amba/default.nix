{ config, pkgs, lib, self, home-manager, ... }:

{
  imports = [
    ../../modules/macos
    ../../modules/macos/leisure
    ../../modules/home-manager
    home-manager.darwinModules.home-manager
  ];

  # Hostname matches the flake config name, so `just switch` can derive it via `hostname -s`
  networking.hostName = "amba";
  networking.localHostName = "amba";

  home-manager.users.andy = import ./home.nix;
}
