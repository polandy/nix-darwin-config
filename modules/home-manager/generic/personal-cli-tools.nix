{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    rclone
    tea
    yt-dlp
  ];
}
