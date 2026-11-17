# Portable CLI tools from nixpkgs that are only needed on the Linux hosts.
# Shared tools live in generic/cli-tools.nix.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    rclone
    yt-dlp
  ];
}
