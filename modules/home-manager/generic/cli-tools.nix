# Portable command-line tools for every host, installed from nixpkgs so all
# machines share one list and the versions pinned in flake.lock.
#
# Only plain CLI tools without a `programs.<name>` module belong here; tools
# with a module are enabled in their own file. See README "Package Management
# Strategy" for what stays in metapac.
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Files & search
    bat
    dust
    fd
    ncdu
    ripgrep
    tree
    vivid

    # Data & scripting
    jq
    just

    # Dev
    gh
    sops

    # Archives
    p7zip

    # Backup
    restic

    # Media
    imagemagick

    # Monitoring
    htop
  ];
}
