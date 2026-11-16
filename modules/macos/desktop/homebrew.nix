{ config, pkgs, lib, self, ... }:

{
  homebrew = {
    taps = [
      "kvndrsslr/formulae"
      "nikitabobko/tap"
    ];
    brews = [
      "ifstat" # sketchybar network widget
      "mas" # needed for masApps
      "herdr"
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
      "whatsapp"
      "font-sketchybar-app-font"
    ];
  };
}
