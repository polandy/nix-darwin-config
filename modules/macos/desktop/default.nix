{ config, pkgs, lib, self, ... }:

{
  imports = [
    ./homebrew.nix
    ./mas-apps.nix
    ./ui.nix
    ./input.nix
    ./fonts.nix
  ];
}
