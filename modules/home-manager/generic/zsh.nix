{ config, pkgs, lib, ... }:

{
  # Zsh integrations for tools already enabled in fish.nix
  programs.zoxide.enableZshIntegration = true;
  programs.mise.enableZshIntegration = true;

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autocd = true;

    history = {
      size = 50000;
      save = 50000;
      extended = true;
      share = true;
      ignoreDups = true;
      ignoreAllDups = true;
    };

    plugins = [
      # fzf-tab must be loaded after compinit and before other completion plugins
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
      {
        name = "zsh-abbr";
        src = pkgs.zsh-abbr;
        file = "share/zsh-abbr/zsh-abbr.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
    ];

    # Numeric directory navigation — function names can't start with digits in zsh
    shellAliases = {
      "1.." = "cd ../";
      "2.." = "cd ../../";
      "3.." = "cd ../../../";
      "4.." = "cd ../../../../";
      "5.." = "cd ../../../../../";
      "6.." = "cd ../../../../../../";
      "7.." = "cd ../../../../../../../";
      "8.." = "cd ../../../../../../../../";
      "9.." = "cd ../../../../../../../../../";
    };

    initContent = lib.mkMerge [
      # Before compinit (order 550)
      (lib.mkOrder 550 ''
        # Homebrew (macOS only)
        if [[ -d /opt/homebrew ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
      '')

      # After compinit (default order)
      ''
        # fzf-tab: use fzf for all tab completions
        zstyle ':fzf-tab:*' fzf-min-height 15
        zstyle ':fzf-tab:*' switch-group '<' '>'
        # Show file preview when completing cd
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons $realpath 2>/dev/null || ls $realpath'
        # Substring matching for all completions
        zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

        # VI mode
        bindkey -v
        export KEYTIMEOUT=1

        # Autosuggestion config (matches fish autosuggestion colour)
        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#949494'
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)

        # Key bindings (matching fish config)
        bindkey '^E' autosuggest-execute    # Ctrl+E: accept suggestion and execute
        bindkey '^H' backward-kill-word     # Ctrl+Backspace
        bindkey '^[[1;5D' backward-word     # Ctrl+Left
        bindkey '^[[1;5C' forward-word      # Ctrl+Right

        # macOS locale
        function darwin_locale() {
          export LANG=en_US.UTF-8
          export LC_ALL=en_US.UTF-8
          export LC_CTYPE=en_US.UTF-8
        }

        # Archive extractor (ported from fish)
        function x() {
          if [[ -z "$1" ]]; then
            echo "Error: No file specified."
            return 1
          fi
          for f in "$@"; do
            if [[ -e "$f" ]]; then
              case "$f" in
                *.tar.bz2) tar xvjf "$f" ;;
                *.tar.gz)  tar xvzf "$f" ;;
                *.bz2)     bunzip2 "$f" ;;
                *.rar)     unrar x "$f" ;;
                *.gz)      gunzip "$f" ;;
                *.tar)     tar xvf "$f" ;;
                *.tbz2)    tar xvjf "$f" ;;
                *.tgz)     tar xvzf "$f" ;;
                *.zip)     unzip "$f" ;;
                *.Z)       uncompress "$f" ;;
                *.7z)      7z x "$f" ;;
                *)         echo "'$f' cannot be extracted via x" ;;
              esac
            else
              echo "'$f' is not a valid file"
            fi
          done
        }

        # File growth speed monitor (ported from fish)
        function speed() {
          while true; do
            local old new spd size
            old=$(du -sk "$1" | cut -f1)
            sleep 1
            new=$(du -sk "$1" | cut -f1)
            spd=$(( new - old ))
            size=$(du -sh "$1" | cut -f1)
            echo "$spd KB/s - $size"
          done
        }

        # Git branch cleanup (ported from fish)
        function git_clean_branches() {
          local base_branch=develop
          git checkout "$base_branch"
          git fetch -p
          while IFS= read -r branch; do
            if ! git branch -r | xargs -n1 basename | grep -qx "$branch"; then
              git branch -d "$branch"
            fi
          done < <(git branch --merged "$base_branch" \
            | grep -v "\(master\|$base_branch\|\*\)" \
            | awk '{print $1}')
        }
      ''
    ];
  };

  # Abbreviations for zsh-abbr (same as fish shellAbbrs).
  # This file is nix-managed (read-only). Add new abbreviations here, not via `abbr add`.
  home.file.".config/zsh-abbr/user-abbreviations".text = ''
    abbr nrs='darwin-rebuild switch --flake .'
    abbr nrb='darwin-rebuild build --flake .'
    abbr nfmt='nix fmt'
    abbr ls='eza'
    abbr ll='eza -l --icons=auto'
    abbr la='eza -la --icons=auto'
    abbr lt='eza --tree --icons=auto'
  '';
}
