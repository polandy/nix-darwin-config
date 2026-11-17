{ pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    dust
    fd
    gh
    htop
    imagemagick
    jq
    just
    ncdu
    p7zip
    restic
    ripgrep
    sops
    tree
    vivid
  ];
}
