{ config, pkgs, lib, self, ... }:

{
  homebrew = {
    # Note that enabling this option does not install Homebrew, see the Homebrew website for installation instructions.
    enable = true;
    # This uninstalls all formulae not listed in the generated Brewfile,
    # and if the formula is a cask, removes all files associated with that cask.
    # In other words, brew uninstall --zap is run for all those formulae.
    onActivation.cleanup = "zap";
    # Caveat: Homebrew kennt kein Versions-Pinning. Was hier steht, wird immer in
    # der jeweils aktuellen Upstream-Version installiert -- diese Pakete sind, anders
    # als alles aus nixpkgs, nicht über flake.lock reproduzierbar. Deshalb gilt:
    # was in nixpkgs für aarch64-darwin sauber baut, gehört nach packages.nix.
    taps = [
      "kvndrsslr/formulae"
    ];
    brews = [
      "ifstat" # nicht in nixpkgs
    ];
    casks = [
      # Bewusst hier statt in nixpkgs -- Begruendung je Eintrag:
      "visual-studio-code" # nixpkgs hinkt ~2 Minor-Releases hinterher
      "firefox" # Hauptbrowser: Cask patcht am selben Tag, der Nix-Store erst beim naechsten flake update
      "logseq" # nixpkgs-Paket verwaist (0.10.x statt 2.x) und an insecure electron gebunden
      "stolendata-mpv" # nixpkgs mpv hat keinen aarch64-darwin-Support
      "google-chrome"
      "tailscale-app"
      "whatsapp"
      "claude-code"
      "font-sketchybar-app-font"
    ];
  };
}
