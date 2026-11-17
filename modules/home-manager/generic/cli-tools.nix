# Portable command-line tools for every host (macOS and Arch), installed from
# nixpkgs so all machines share one list and the versions pinned in flake.lock.
#
# Only plain CLI tools without a `programs.<name>` module belong here. Tools
# with a module (git, tmux, neovim, fzf, zoxide, eza, mise, ...) are enabled in
# their own file. Tools only for personal hosts live in personal-cli-tools.nix.
# System-level, hardware, daemon and GUI packages on Arch stay in metapac
# (see README "Package Management Strategy").
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
