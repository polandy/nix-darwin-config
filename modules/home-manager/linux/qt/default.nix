{ config, ... }:

# Qt apps go through qt6ct (QT_QPA_PLATFORMTHEME in hyprland.conf): Breeze
# widgets with a Catppuccin Macchiato palette.
{
  xdg.configFile."qt6ct/colors/catppuccin-macchiato.conf".source = ./catppuccin-macchiato.conf;
  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=${config.xdg.configHome}/qt6ct/colors/catppuccin-macchiato.conf
    custom_palette=true
    icon_theme=breeze-dark
    standard_dialogs=default
    style=Breeze

    [Fonts]
    fixed="JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
    general="Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
  '';
}
