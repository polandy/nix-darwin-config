# CLI tools from nixpkgs for the personal machines only (amba, x1, coolermaster),
# not the work laptop (ambp). Not part of generic/default.nix: personal hosts
# import it explicitly. Tools for every host live in generic/cli-tools.nix.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    aria2
    rclone
    yt-dlp
  ];
}
