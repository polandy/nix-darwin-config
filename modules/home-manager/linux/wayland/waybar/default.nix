{ ... }:

{
  # waybar package is managed by metapac (Arch).
  xdg.configFile."waybar" = { source = ./files; recursive = true; };
}
