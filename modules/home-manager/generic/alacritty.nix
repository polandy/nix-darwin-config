{ pkgs, ... }: {
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = { family = "FiraCode Nerd Font"; style = "Regular"; };
        bold = { family = "FiraCode Nerd Font"; style = "Bold"; };
        italic = { family = "FiraCode Nerd Font"; style = "Italic"; };
        bold_italic = { family = "FiraCode Nerd Font"; style = "Bold Italic"; };
      };
      window = {
        dynamic_padding = false;
        opacity = 0.98;
        padding = { x = 5; y = 5; };
      } // (if pkgs.stdenv.isDarwin then {
        decorations = "buttonless";
        option_as_alt = "Both";
      } else {});
      env.TERM = "xterm-256color";
      keyboard.bindings = [
        { action = "ReceiveChar"; key = "F"; mods = "Command|Shift"; }
        { key = "Return"; mods = "Shift"; chars = "\\u001B\\r"; }
      ];
    };
  };
}
