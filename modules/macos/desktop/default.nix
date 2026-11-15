{ config, pkgs, lib, self, ... }:

# Everything that only makes sense with a screen, keyboard and a logged-in user:
# GUI apps, UI defaults, input settings, fonts, App Store apps.
{
  imports = [
    ./homebrew.nix
    ./mas-apps.nix
    ./ui.nix
    ./input.nix
    ./fonts.nix
  ];
}
