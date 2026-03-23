{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/generic/syncthing.nix
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/macos/aerospace-desktop
  ];

  home.stateVersion = "24.05"; # Match a recent stable version or unstable
  home.username = "andy";
  home.homeDirectory = "/Users/andy";

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
