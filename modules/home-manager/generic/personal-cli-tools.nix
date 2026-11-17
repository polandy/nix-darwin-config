# CLI tools from nixpkgs for personal machines only, not work machines.
# Not part of generic/default.nix: personal hosts import it explicitly.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    rclone
    yt-dlp
  ];
}
