{ inputs }:
let
  inherit (inputs) self nixpkgs nix-darwin home-manager sops-nix system-manager;
in
{
  mkDarwin = { host, system ? "aarch64-darwin", modules ? [ ] }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = { inherit self home-manager sops-nix; };
      modules = [
        (self + "/hosts/${host}")
        {
          # Nix daemon is managed by the Determinate Systems installer, not nix-darwin
          nix.enable = false;
        }
      ] ++ modules;
    };

  mkHome = { host, system ? "x86_64-linux", modules ? [ ] }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.${system};
      extraSpecialArgs = { inherit sops-nix; };
      modules = [
        (self + "/hosts/${host}/home.nix")
        sops-nix.homeManagerModules.sops
      ] ++ modules;
    };

  mkSystem = { host, system ? "x86_64-linux", modules ? [ ] }:
    system-manager.lib.makeSystemConfig {
      modules = [
        (self + "/hosts/${host}/system.nix")
        { nixpkgs.hostPlatform = system; }
      ] ++ modules;
    };
}
