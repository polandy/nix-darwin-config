{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/generic/claude-code
  ];
}
