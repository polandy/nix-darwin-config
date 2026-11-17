# Packages are installed via `metapac sync`, not home-manager.
{ ... }:

{
  xdg.configFile."metapac/config.toml".source = ./config.toml;
  xdg.configFile."metapac/groups".source = ./groups;
}
