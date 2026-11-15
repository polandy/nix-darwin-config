{ config, pkgs, self, ... }:

# Shared by every Mac, with or without a desktop. GUI-only settings and apps
# live in ./desktop, imported per host.
{
  imports = [
    ./base
    ./system.nix
  ];
}
