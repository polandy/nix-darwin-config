# Imported per host, not via generic/default.nix.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    rclone
    yt-dlp
  ];
}
