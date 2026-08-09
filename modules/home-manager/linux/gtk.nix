{ config, pkgs, ... }:

{
  gtk = {
    enable = true;
    theme.name = "Breeze";
    iconTheme.name = "breeze";
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
    # Upstream changed this default from config.gtk.theme to null, because a GTK3
    # theme name has no effect on libadwaita apps. Set explicitly to keep the
    # previous behaviour: non-libadwaita GTK4 apps stay on Breeze like GTK3.
    gtk4.theme = config.gtk.theme;

    gtk4.extraConfig = {
      gtk-cursor-blink = true;
      gtk-cursor-blink-time = 1000;
      gtk-decoration-layout = "icon:minimize,maximize,close";
      gtk-enable-animations = true;
      gtk-primary-button-warps-slider = true;
      gtk-sound-theme-name = "ocean";
      gtk-xft-dpi = 98304;
    };
  };

  home.pointerCursor = {
    name = "breeze_cursors";
    size = 24;
    package = pkgs.kdePackages.breeze;
  };
}
