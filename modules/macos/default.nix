{ config, pkgs, self, ... }:

{
  imports = [
    ./base
    ./ui.nix
    ./hardware.nix
    ./system.nix
    ./fonts.nix
  ];
}
