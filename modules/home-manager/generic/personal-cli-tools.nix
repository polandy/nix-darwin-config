{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    rclone
    yt-dlp
  ];
}
