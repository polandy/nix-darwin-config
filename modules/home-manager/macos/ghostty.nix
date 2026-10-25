{ ... }: {
  programs.ghostty = {
    enable = true;
    # The app comes from the Homebrew cask so its path in /Applications stays
    # stable and macOS privacy grants (e.g. Full Disk Access) survive updates.
    package = null;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      background-opacity = 0.98;
      window-padding-x = 5;
      window-padding-y = 5;
      window-padding-balance = false;
      macos-titlebar-style = "hidden";
      macos-option-as-alt = true;
      term = "xterm-256color";
      keybind = [
        "super+shift+f=unbind"
        "shift+enter=text:\\x1b\\r"
      ];
    };
  };
}
