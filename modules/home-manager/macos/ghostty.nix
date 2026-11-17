{ ... }: {
  programs.ghostty = {
    enable = true;
    # App comes from the Homebrew cask: privacy grants are tied to its path.
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
