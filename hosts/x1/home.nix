{ config, pkgs, ... }: {
  nixpkgs.config.allowUnfree = true;

  imports = [
    ../../modules/home-manager/generic
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/linux
  ];

  home.stateVersion = "24.05";
  home.username = "andy";
  home.homeDirectory = "/home/andy";

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  programs.home-manager.enable = true;
}
