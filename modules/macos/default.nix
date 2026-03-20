{ config, pkgs, self, ... }:

{
  imports = [
    ./base
    ./ui.nix
    ./input.nix
    ./system.nix
    ./fonts.nix
  ];
}
