{ config, pkgs, self, ... }:

{
  imports = [
    ./base
    ./system.nix
  ];
}
