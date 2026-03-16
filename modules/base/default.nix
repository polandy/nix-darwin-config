{ config, pkgs, self, ... }:

{
  imports = [
    ./packages.nix
    ./homebrew.nix
    ./mas-apps.nix
    ./user.nix
  ];

  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";


  # Enable alternative shell support in nix-darwin.
  programs.fish = {
    enable = true;
    shellAbbrs = {
      nrs = "darwin-rebuild switch --flake .";
      nrb = "darwin-rebuild build --flake .";
      nfmt = "nix fmt";
    };
  };

  environment.variables = {
    editor = "nvim";
    LANG = "en_US.UTF-8";
  };

  system = {
    # Set Git commit hash for darwin-version.
    configurationRevision = self.rev or self.dirtyRev or null;
    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    stateVersion = 5;
  };

}
