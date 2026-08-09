{ pkgs, ... }:

{
  imports = [
    ./niri
    ./hypr
    ./kanshi
    ./mako
    ./waybar
  ];

  home.packages = with pkgs; [
    # compositors
    niri
    xwayland-satellite

    # screenshots
    grim
    slurp

    # clipboard
    wl-clipboard
    cliphist

    # wallpaper / idle
    awww # upstream rename of swww; binaries are awww / awww-daemon
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
