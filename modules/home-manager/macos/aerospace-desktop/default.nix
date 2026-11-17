{ config, pkgs, lib, ... }:

{
  imports = [
    ./aerospace.nix
    ./jankyborders.nix
    ./sketchybar.nix
  ];

  # aerospace must come from the Homebrew cask: Accessibility permission is tied to the binary path.
  home.packages = with pkgs; [
    sketchybar
    jankyborders
    sketchybar-app-font
  ];
}
