{ ... }:

{
  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "application/json" = [ "userapp-code-19WDS2.desktop" ];
      "application/pdf" = [ "userapp-evince-ZHXC32.desktop" ];
      "application/x-shellscript" = [ "userapp-code-19WDS2.desktop" ];
      "application/x-zerosize" = [ "Alacritty.desktop" ];
      "audio/mpeg" = [ "vlc.desktop" ];
      "image/jpeg" = [ "org.geeqie.Geeqie.desktop" "brave-browser.desktop" ];
      "image/x-fuji-raf" = [ "darktable.desktop" ];
      "image/x-adobe-dng" = [ "org.geeqie.Geeqie.desktop" ];
      "text/csv" = [ "libreoffice-calc.desktop" "code.desktop" ];
      "text/markdown" = [ "userapp-code-19WDS2.desktop" ];
      "text/x-nfo" = [ "vim.desktop" "nvim.desktop" ];
      "video/mp4" = [ "mpv.desktop" "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" "mpv.desktop" ];
      "video/vnd.avi" = [ "vlc.desktop" "mpv.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" "mpv.desktop" ];
      "application/epub+zip" = [ "calibre-ebook-viewer.desktop" ];
    };
    defaultApplications = {
      "application/json" = "userapp-code-19WDS2.desktop";
      "application/x-zerosize" = "Alacritty.desktop";
      "image/x-fuji-raf" = "darktable.desktop";
      "inode/directory" = "thunar.desktop";
      "text/html" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/discord-460807638964371468" = "discord-460807638964371468.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";
    };
  };
}
