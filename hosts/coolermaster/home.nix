{ config, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/generic
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/linux
  ];

  news.display = "silent";
}
