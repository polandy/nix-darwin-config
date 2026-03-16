{ config, pkgs, lib, ... }:

{
  xdg.configFile."sketchybar" = {
    source = ./sketchybar_config;
    recursive = true;
  };

  # After darwin-rebuild switch, the new config files are written but sketchybar
  # won't pick them up until reloaded. This activation hook does that automatically,
  # but only if sketchybar is already running (i.e. we're in a live session).
  home.activation.reloadSketchybar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if pgrep -x sketchybar > /dev/null; then
      ${pkgs.sketchybar}/bin/sketchybar --reload
    fi
  '';
}
