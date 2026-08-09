{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.bat
    pkgs.coreutils # gnu core utilities
    pkgs.git
    pkgs.findutils
    pkgs.gh
    pkgs.gnused
    pkgs.htop
    pkgs.just
    pkgs.mas
    pkgs.mise
    pkgs.ncdu
    pkgs.p7zip
    pkgs.unrar # RAR5-Support; extract-Funktion nutzt `unrar x`
    pkgs.tmux
    pkgs.tree
    pkgs.unixtools.watch
    pkgs.wget
    pkgs.vivid

    pkgs.sops
    pkgs.age
    pkgs.ssh-to-age

    pkgs.lua
    pkgs.ripgrep
    pkgs.fd
    pkgs.fzf
    pkgs.cargo
    pkgs.lazygit
    pkgs.mcp-nixos
    pkgs.zoxide
    pkgs.gemini-cli

    # GUI apps. mac-app-util turns these into aliases under /Applications/Nix Apps
    # so that Spotlight can find them.
    pkgs.brave
    pkgs.obsidian
    pkgs.raycast
    pkgs.utm
  ];

}
