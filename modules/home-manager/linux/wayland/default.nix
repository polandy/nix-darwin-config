{ config, pkgs, ... }:

{
  imports = [
    ./niri.nix
  ];

  home.packages = with pkgs; [
    # compositors
    hyprland
    hyprlock
    hypridle
    niri
    xwayland-satellite

    # screenshots
    grim
    slurp

    # clipboard
    wl-clipboard
    cliphist

    # display management
    wdisplays
    wlr-randr
    nwg-displays
    kanshi

    # wallpaper / idle
    swww
    swayidle
    swaybg

    # launcher
    wofi

    # status bar
    waybar

    # backlight
    brightnessctl

    # misc
    cava
    matugen
    foot
  ];

  home.file.".config/hypr".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/hypr";

  home.file.".config/waybar".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/waybar";

  home.file.".config/wofi".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/wofi";

  home.file.".config/kanshi".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/kanshi";

  home.file.".config/mako".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/mako";
}
