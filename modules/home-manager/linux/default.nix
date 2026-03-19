{ ... }: {
  imports = [
    ./packages.nix
    # Add WM modules incrementally:
    # ./hyprland.nix
    # ./waybar.nix
  ];
}
