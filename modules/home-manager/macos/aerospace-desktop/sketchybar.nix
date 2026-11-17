{ config, pkgs, lib, ... }:

{
  xdg.configFile."sketchybar" = {
    source = ./sketchybar_config;
    recursive = true;
  };

  home.activation.reloadSketchybar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if /usr/bin/pgrep -x sketchybar > /dev/null; then
      ${pkgs.sketchybar}/bin/sketchybar --reload
    fi
  '';
}
