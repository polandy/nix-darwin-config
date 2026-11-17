{ config, pkgs, lib, ... }:

{
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
      # fzf-tab: after compinit, before other completion plugins
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

    # Function names can't start with digits in zsh
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
      (lib.mkOrder 550 ''
        if [[ -d /opt/homebrew ]]; then
          eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
      '')

      ''
        zstyle ':fzf-tab:*' fzf-min-height 15
        zstyle ':fzf-tab:*' switch-group '<' '>'
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --tree --color=always --icons $realpath 2>/dev/null || ls $realpath'
        zstyle ':completion:*' matcher-list ''' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

        bindkey -v
        export KEYTIMEOUT=1

        ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#949494'
        ZSH_AUTOSUGGEST_STRATEGY=(history completion)

        bindkey '^E' autosuggest-execute    # Ctrl+E: accept suggestion and execute
        bindkey '^H' backward-kill-word     # Ctrl+Backspace
        bindkey '^[[1;5D' backward-word     # Ctrl+Left
        bindkey '^[[1;5C' forward-word      # Ctrl+Right

        function darwin_locale() {
          export LANG=en_US.UTF-8
          export LC_ALL=en_US.UTF-8
          export LC_CTYPE=en_US.UTF-8
        }

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

  # Nix-managed (read-only): add abbreviations here, not via `abbr add`.
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
