# Shared home-manager baseline for all hosts. Everything uses mkDefault so a
# host can still override individual values in its home.nix.
{ config, pkgs, lib, ... }:

{
  home.username = lib.mkDefault "andy";
  home.homeDirectory = lib.mkDefault
    (if pkgs.stdenv.isDarwin then "/Users/andy" else "/home/andy");
  home.stateVersion = lib.mkDefault "24.05";

  sops.age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  home.sessionVariables.SOPS_AGE_KEY_FILE =
    lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
