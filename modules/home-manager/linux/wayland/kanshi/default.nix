{ pkgs, ... }:

{
  home.packages = with pkgs; [
    kanshi
    wdisplays
    wlr-randr
    nwg-displays
  ];

  xdg.configFile."kanshi/config".source = ./config;
}
