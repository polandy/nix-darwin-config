{ config, pkgs, self, ... }:

{
  users.users.andy = {
    name = "andy";
    home = "/Users/andy";
    shell = pkgs.fish;
  };
  system = {
    primaryUser = "andy";
  };
}
