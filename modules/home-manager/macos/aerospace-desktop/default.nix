{ config, pkgs, lib, ... }:

{
  imports = [
    ./aerospace.nix
    ./jankyborders.nix
    ./sketchybar.nix
  ];

  # aerospace intentionally NOT installed here — it comes from the Homebrew
  # cask (modules/macos/base/homebrew.nix) so its binary path stays stable
  # and macOS Accessibility permissions survive updates. The cask also ships
  # the `aerospace` CLI in /opt/homebrew/bin.
  home.packages = with pkgs; [
    sketchybar
    jankyborders
    sketchybar-app-font
  ];
}
