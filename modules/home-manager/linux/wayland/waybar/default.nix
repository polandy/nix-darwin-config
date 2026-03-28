{ pkgs, ... }:

{
  home.packages = with pkgs; [
    waybar
  ];

  xdg.configFile."waybar" = { source = ./files; recursive = true; };
}
