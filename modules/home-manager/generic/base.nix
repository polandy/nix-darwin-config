{ config, pkgs, lib, ... }:

{
  home.username = lib.mkDefault "andy";
  home.homeDirectory = lib.mkDefault
    (if pkgs.stdenv.hostPlatform.isDarwin then "/Users/andy" else "/home/andy");
  home.stateVersion = lib.mkDefault "24.05";

  news.display = lib.mkDefault "silent";

  sops.age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  home.sessionVariables.SOPS_AGE_KEY_FILE =
    lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";

  programs.home-manager.enable = true;
}
