{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.coreutils # gnu core utilities
    pkgs.git
    pkgs.findutils
    pkgs.gnused
    pkgs.mas
    pkgs.unrar # RAR5-Support; extract-Funktion nutzt `unrar x`
    pkgs.unixtools.watch
    pkgs.wget

    pkgs.age
    pkgs.ssh-to-age

    pkgs.lua
    pkgs.cargo
    pkgs.lazygit
  ];

}
