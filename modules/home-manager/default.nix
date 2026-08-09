{ config, pkgs, lib, sops-nix, mac-app-util, ... }:

{
  # These are nix-darwin options that tell the macOS system builder how to integrate with Home Manager.
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "backup";

  # Include sops-nix home-manager module for all hosts
  home-manager.sharedModules = [
    sops-nix.homeManagerModules.sops
    # Aliases for .app bundles coming from home.packages (Alacritty, AeroSpace).
    # The counterpart for environment.systemPackages lives in lib/default.nix.
    mac-app-util.homeManagerModules.default
    # Do not disable targets.darwin.linkApps to get rid of the seemingly
    # redundant ~/Applications/Home Manager Apps: mac-app-util reads that
    # directory as the *source* for sync-trampolines and writes the aliases to
    # ~/Applications/Home Manager Trampolines. Turning linkApps off removes the
    # source, and the trampolines get pruned along with it.
    ./generic # fish + git for all hosts
  ];
}
