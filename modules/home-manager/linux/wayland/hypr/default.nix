{ pkgs, ... }:

{
  xdg.configFile."hypr/hyprland.lua".source = ./hyprland.lua;
  xdg.configFile."hypr/hypridle.conf".source = ./hypridle.conf;
  xdg.configFile."hypr/hyprlock.conf".source = ./hyprlock.conf;

  home.file.".local/bin/hyprlock-safe" = {
    source = ./hyprlock-safe;
    executable = true;
  };
}
