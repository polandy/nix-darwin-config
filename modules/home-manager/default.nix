{ config, pkgs, lib, sops-nix, ... }:

{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  home-manager.sharedModules = [
    sops-nix.homeManagerModules.sops
    ./generic
  ];
}
