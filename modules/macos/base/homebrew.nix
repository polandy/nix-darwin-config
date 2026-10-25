{ config, pkgs, lib, self, ... }:

{
  homebrew = {
    # Note that enabling this option does not install Homebrew, see the Homebrew website for installation instructions.
    enable = true;
    # This uninstalls all formulae not listed in the generated Brewfile,
    # and if the formula is a cask, removes all files associated with that cask.
    # In other words, brew uninstall --zap is run for all those formulae.
    onActivation.cleanup = "zap";
    taps = [
      "kvndrsslr/formulae"
      "nikitabobko/tap"
    ];
    brews = [
      "ifstat"
      "mas"
      "gemini-cli"
    ];
    casks = [
      # AeroSpace must come from Homebrew, not nixpkgs: macOS ties the
      # Accessibility permission to the binary path, and nix store paths
      # change on every update, silently breaking all hotkeys.
      "nikitabobko/tap/aerospace"
      # Alacritty is disabled upstream since 2026-09-01 (not notarized, fails
      # Gatekeeper): the installed app keeps working but gets no updates.
      "alacritty"
      # Notarized alternative to Alacritty, currently being trialled.
      "ghostty"
      "raycast"
      "utm"
      "visual-studio-code"
      "brave-browser"
      "stolendata-mpv"
      "firefox"
      "google-chrome"
      "logseq"
      "obsidian"
      "tailscale-app"
      "whatsapp"
      "claude-code"
      "font-sketchybar-app-font"
    ];
  };
}
