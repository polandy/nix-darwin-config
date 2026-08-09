# Helpers for constructing host configurations, so flake.nix stays declarative:
# one line per host. Adding a machine means adding a single mkDarwin/mkHome call.
{ inputs }:
let
  inherit (inputs) self nixpkgs nix-darwin home-manager sops-nix mac-app-util;
in
{
  # macOS host via nix-darwin. Host-specific modules (base, devops/leisure, home-manager)
  # are composed in hosts/<host>/default.nix.
  mkDarwin = { host, system ? "aarch64-darwin", modules ? [ ] }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self home-manager sops-nix mac-app-util; };
      modules = [
        (self + "/hosts/${host}")
        mac-app-util.darwinModules.default
        {
          # The Nix daemon is managed by the Determinate Systems installer, not
          # nix-darwin. https://github.com/DeterminateSystems/nix-installer
          nix.enable = false;
        }
      ] ++ modules;
    };

  # Linux host via standalone home-manager. Host config lives in hosts/<host>/home.nix.
  mkHome = { host, system ? "x86_64-linux", modules ? [ ] }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit sops-nix; };
      modules = [
        (self + "/hosts/${host}/home.nix")
        sops-nix.homeManagerModules.sops
      ] ++ modules;
    };
}
