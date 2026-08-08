# metapac declares which pacman/AUR packages each Arch host gets; home-manager
# only deploys its config so this repo stays the single source of truth.
# Package installation itself still happens via `metapac sync` on the host.
{ ... }:

{
  xdg.configFile."metapac/config.toml".source = ./config.toml;
  xdg.configFile."metapac/groups".source = ./groups;
}
