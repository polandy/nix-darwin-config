{ pkgs, ... }:

{
  xdg.configFile."hypr/hyprland.conf".source = ./hyprland.conf;
  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;
}
