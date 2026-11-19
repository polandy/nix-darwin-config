{ pkgs, ... }:

{
  environment.systemPackages = [
    pkgs.coreutils
    pkgs.git
    pkgs.findutils
    pkgs.gnused
    pkgs.unrar # RAR5; extract nutzt `unrar x`
    pkgs.unixtools.watch
    pkgs.wget

    pkgs.age
    pkgs.ssh-to-age

    pkgs.lua
    pkgs.cargo
    pkgs.lazygit
  ];

}
