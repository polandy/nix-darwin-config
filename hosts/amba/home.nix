{ config, pkgs, ... }:

{
  imports = [
    ../../modules/home-manager/syncthing.nix
    ../../modules/home-manager/ssh.nix
    ../../modules/home-manager/macos-aerospace-desktop
  ];

  home.stateVersion = "24.05"; # Match a recent stable version or unstable
  home.username = "andy";
  home.homeDirectory = "/Users/andy";

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
