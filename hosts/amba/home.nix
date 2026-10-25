{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/macos/syncthing.nix
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/macos/aerospace-desktop
    ../../modules/home-manager/macos/ghostty.nix
  ];
}
