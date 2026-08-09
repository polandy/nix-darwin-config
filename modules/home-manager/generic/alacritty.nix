{ pkgs, ... }: {
  home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  programs.alacritty = {
    enable = true;
    # The binary comes from the host package manager on both platforms, so use a
    # stub: home-manager still generates ~/.config/alacritty/alacritty.toml, but
    # installs nothing.
    #
    # Linux: on non-NixOS, Nix-packaged alacritty can't find host GPU drivers.
    #
    # macOS (Homebrew cask): darwin-rebuild needs the App Management permission
    # for the terminal it runs in, and macOS ties that permission to the
    # executable path. From nixpkgs that path is /nix/store/<hash>-alacritty-*,
    # so every update would invalidate the grant and abort the next rebuild. The
    # cask keeps alacritty at the stable /Applications/Alacritty.app. This is the
    # same class of problem as the login items described in docs/aerospace.md.
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
      } // (if pkgs.stdenv.isDarwin then {
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
