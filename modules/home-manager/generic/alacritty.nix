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
      env.TERM = "xterm-256color";
      keyboard.bindings = [
        { action = "ReceiveChar"; key = "F"; mods = "Command|Shift"; }
        { key = "Return"; mods = "Shift"; chars = "\\u001B\\r"; }
      ];
    };
  };
}
