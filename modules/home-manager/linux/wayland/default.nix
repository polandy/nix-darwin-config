{ pkgs, ... }:

{
  imports = [
    ./hypr
    ./kanshi
    ./mako
    ./waybar
  ];

  home.packages = with pkgs; [
    # screenshots
    grim
    slurp

    # clipboard
    wl-clipboard
    cliphist

    # wallpaper / idle
    swww
    swayidle
    swaybg

    # backlight
    brightnessctl

    # misc
    cava
    matugen
    foot
  ];

}
