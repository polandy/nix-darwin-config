{ pkgs, ... }:

let
  # timeshift-autosnap runs as root from a pacman hook and needs the user's
  # session bus to send desktop notifications
  wrapper = pkgs.writeShellScript "timeshift" ''
    if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
      for bus in /run/user/*/bus; do
        [ -S "$bus" ] && export DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" && break
      done
    fi
    exec /usr/bin/timeshift "$@"
  '';
in
{
  systemd.tmpfiles.rules = [ "L+ /usr/local/bin/timeshift - - - - ${wrapper}" ];
}
