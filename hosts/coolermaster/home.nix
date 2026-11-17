{ config, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/generic
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/linux
  ];

  xdg.configFile."hypr/host.lua".source = ./hyprland.lua;
}
