{ config, pkgs, ... }:

let
  # Catppuccin Macchiato on top of adw-gtk3 / libadwaita named colors,
  # matches waybar/dunst/hyprland.
  catppuccinCss = ''
    @define-color accent_color #8aadf4;
    @define-color accent_bg_color #8aadf4;
    @define-color accent_fg_color #181926;
    @define-color destructive_color #ed8796;
    @define-color destructive_bg_color #ed8796;
    @define-color destructive_fg_color #181926;
    @define-color success_color #a6da95;
    @define-color success_bg_color #a6da95;
    @define-color success_fg_color #181926;
    @define-color warning_color #eed49f;
    @define-color warning_bg_color #eed49f;
    @define-color warning_fg_color #181926;
    @define-color error_color #ed8796;
    @define-color error_bg_color #ed8796;
    @define-color error_fg_color #181926;

    @define-color window_bg_color #24273a;
    @define-color window_fg_color #cad3f5;
    @define-color view_bg_color #1e2030;
    @define-color view_fg_color #cad3f5;
    @define-color headerbar_bg_color #1e2030;
    @define-color headerbar_fg_color #cad3f5;
    @define-color headerbar_border_color #363a4f;
    @define-color headerbar_backdrop_color #24273a;
    @define-color headerbar_shade_color rgba(0, 0, 0, 0.36);
    @define-color sidebar_bg_color #1e2030;
    @define-color sidebar_fg_color #cad3f5;
    @define-color sidebar_backdrop_color #24273a;
    @define-color sidebar_shade_color rgba(0, 0, 0, 0.36);
    @define-color card_bg_color #363a4f;
    @define-color card_fg_color #cad3f5;
    @define-color card_shade_color rgba(0, 0, 0, 0.36);
    @define-color dialog_bg_color #24273a;
    @define-color dialog_fg_color #cad3f5;
    @define-color popover_bg_color #1e2030;
    @define-color popover_fg_color #cad3f5;
    @define-color shade_color rgba(0, 0, 0, 0.36);
    @define-color scrollbar_outline_color rgba(0, 0, 0, 0.5);
  '';
in
{
  gtk = {
    enable = true;
    theme.name = "adw-gtk3-dark";
    gtk4.theme = config.gtk.theme;
    iconTheme.name = "breeze-dark";
    cursorTheme = {
      name = "breeze_cursors";
      size = 24;
    };
    font = {
      name = "Noto Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-button-images = true;
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-menu-images = true;
      gtk-modules = "colorreload-gtk-module";
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-toolbar-style = 3;
      gtk-xft-dpi = 98304;
    };
    gtk3.extraCss = catppuccinCss;
    gtk4.extraConfig = {
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
    gtk4.extraCss = catppuccinCss;
  };

  # libadwaita apps follow this instead of the GTK theme name
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  home.pointerCursor = {
    enable = true;
    name = "breeze_cursors";
    size = 24;
    package = pkgs.kdePackages.breeze;
  };
}
