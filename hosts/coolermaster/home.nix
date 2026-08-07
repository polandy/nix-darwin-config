{ config, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/generic
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/linux
  ];

  home.packages = with pkgs; [
    calibre
    ansible
  ];

  news.display = "silent";
}
