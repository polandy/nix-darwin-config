{ pkgs, ... }: {
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs.alacritty = {
    enable = true;
    # The binary comes from the system package manager, not Nix: on macOS
    # via the Homebrew cask, and on non-NixOS Linux because Nix-packaged
    # alacritty can't find host GPU drivers. Use a stub so home-manager
    # still generates the config without installing the Nix package.
    package = pkgs.runCommand "alacritty-stub" { } "mkdir -p $out/bin";
    settings = {
      font = {
        normal = { family = "JetBrainsMono Nerd Font"; style = "Regular"; };
        bold = { family = "JetBrainsMono Nerd Font"; style = "Bold"; };
        italic = { family = "JetBrainsMono Nerd Font"; style = "Italic"; };
        bold_italic = { family = "JetBrainsMono Nerd Font"; style = "Bold Italic"; };
      };
      window = {
        dynamic_padding = false;
        opacity = 0.98;
        padding = { x = 5; y = 5; };
      } // (if pkgs.stdenv.hostPlatform.isDarwin then {
        decorations = "buttonless";
        option_as_alt = "Both";
      } else { });
      # Catppuccin Macchiato — https://github.com/catppuccin/alacritty
      colors = {
        primary = {
          background = "#24273a";
          foreground = "#cad3f5";
          dim_foreground = "#8087a2";
          bright_foreground = "#cad3f5";
        };
        cursor = { text = "#24273a"; cursor = "#f4dbd6"; };
        vi_mode_cursor = { text = "#24273a"; cursor = "#b7bdf8"; };
        search = {
          matches = { foreground = "#24273a"; background = "#a5adcb"; };
          focused_match = { foreground = "#24273a"; background = "#a6da95"; };
        };
        footer_bar = { foreground = "#24273a"; background = "#a5adcb"; };
        hints = {
          start = { foreground = "#24273a"; background = "#eed49f"; };
          end = { foreground = "#24273a"; background = "#a5adcb"; };
        };
        selection = { text = "#24273a"; background = "#f4dbd6"; };
        normal = {
          black = "#494d64";
          red = "#ed8796";
          green = "#a6da95";
          yellow = "#eed49f";
          blue = "#8aadf4";
          magenta = "#f5bde6";
          cyan = "#8bd5ca";
          white = "#b8c0e0";
        };
        bright = {
          black = "#5b6078";
          red = "#ed8796";
          green = "#a6da95";
          yellow = "#eed49f";
          blue = "#8aadf4";
          magenta = "#f5bde6";
          cyan = "#8bd5ca";
          white = "#a5adcb";
        };
        indexed_colors = [
          { index = 16; color = "#f5a97f"; }
          { index = 17; color = "#f4dbd6"; }
        ];
      };
      env.TERM = "xterm-256color";
      keyboard.bindings = [
        { action = "ReceiveChar"; key = "F"; mods = "Command|Shift"; }
        { key = "Return"; mods = "Shift"; chars = "\\u001B\\r"; }
      ];
    };
  };
}
