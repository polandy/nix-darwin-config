{ config, pkgs, lib, self, ... }:

{
  homebrew = {
    # Removed apps are not uninstalled (Homebrew Bundle limitation)
    masApps = {
      wireguard = 1451685025;
      bitwarden = 1352778147;
    };
  };
}
