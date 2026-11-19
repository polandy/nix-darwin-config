{ config, pkgs, self, ... }:

{
  imports = [
    ./packages.nix
    ./homebrew.nix
    ./user.nix
  ];

  nixpkgs.config.allowUnfree = true;

  programs.fish.enable = true;

  environment.variables = {
    EDITOR = "nvim";
    LANG = "en_US.UTF-8";
  };

  system = {
    configurationRevision = self.rev or self.dirtyRev or null;
    stateVersion = 5;
  };

}
