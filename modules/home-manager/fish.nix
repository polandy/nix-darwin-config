{ config, pkgs, lib, ... }:

{
  programs.eza = {
    enable = true;
  };

  programs.fish = {
    enable = true;

    shellAbbrs = {
      nrs = "darwin-rebuild switch --flake .";
      nrb = "darwin-rebuild build --flake .";
      nfmt = "nix fmt";
      ls  = "eza";
      ll  = "eza -l --icons=auto";
      la  = "eza -la --icons=auto";
      lt  = "eza --tree --icons=auto";
    };
    # Homebrew and Mise setup
    shellInit = ''
      if test -d /opt/homebrew
        /opt/homebrew/bin/brew shellenv | source
      end

      if type -q mise
        mise activate fish | source
      end

      if type -q zoxide
        zoxide init fish | source
      end
    '';
    
    # macOS specific key bindings
    interactiveShellInit = ''
      # Kitty keyboard protocol escape sequences
      bind \e\[102\;9u 'forward-word' # command + f
      bind \e\[46\;9u 'history-token-search-backward' # command + . : insert last argument of previous command
    '';

    # Additional macOS shell settings
    functions = {
      darwin_locale = {
        body = ''
          # macOS locale settings
          set -g LANG en_US.UTF-8
          set -x LC_ALL en_US.UTF-8
          set -x LC_CTYPE en_US.UTF-8
        '';
      };
    };
  };
}
