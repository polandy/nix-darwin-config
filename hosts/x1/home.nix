{ config, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../modules/home-manager/generic
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/linux
  ];
}
