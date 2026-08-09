{ config, pkgs, lib, self, ... }:

{
  homebrew = {
    # Note that enabling this option does not install Homebrew, see the Homebrew website for installation instructions.
    enable = true;
    # This uninstalls all formulae not listed in the generated Brewfile,
    # and if the formula is a cask, removes all files associated with that cask.
    # In other words, brew uninstall --zap is run for all those formulae.
    onActivation.cleanup = "zap";
    # Caveat: Homebrew has no concept of version pinning. Whatever is listed here
    # is always installed at the current upstream version, so unlike everything
    # from nixpkgs these packages are not reproducible via flake.lock. Rule of
    # thumb: if it builds cleanly for aarch64-darwin in nixpkgs, it belongs in
    # packages.nix instead.
    taps = [
      "kvndrsslr/formulae"
    ];
    brews = [
      "ifstat" # not in nixpkgs
    ];
    casks = [
      # Deliberately kept on Homebrew rather than nixpkgs, reason per entry:
      # Terminal emulator: darwin-rebuild needs the App Management permission for
      # the terminal it runs in, and macOS ties that permission to the executable
      # path. From nixpkgs that path carries the version hash, so every update
      # would revoke the grant and abort the next rebuild. The cask keeps it at
      # /Applications/Alacritty.app. Config still comes from home-manager, see
      # modules/home-manager/generic/alacritty.nix.
      "alacritty"
      "visual-studio-code" # nixpkgs trails by ~2 minor releases
      "firefox" # main browser: the cask patches same-day, the Nix store only on the next flake update
      "logseq" # nixpkgs package is unmaintained (0.10.x vs 2.x) and pinned to an insecure electron
      "stolendata-mpv" # nixpkgs mpv has no aarch64-darwin support
      "google-chrome"
      "tailscale-app"
      "whatsapp"
      "claude-code"
      "font-sketchybar-app-font"
    ];
  };
}
