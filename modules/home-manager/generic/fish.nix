{ config, pkgs, lib, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs.eza = {
    enable = true;
  };

  programs.mise = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
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

    shellInit = ''
      if test -d /opt/homebrew
        /opt/homebrew/bin/brew shellenv | source
      end
    '';

    interactiveShellInit = ''
      # VI key bindings
      set -g fish_key_bindings fish_vi_key_bindings

      # Theme colors
      set -g fish_color_autosuggestion \#949494
      set -g fish_color_cancel -r
      set -g fish_color_command \#ffff87
      set -g fish_color_comment red
      set -g fish_color_cwd \#00ffff
      set -g fish_color_cwd_root red
      set -g fish_color_end green
      set -g fish_color_error brred
      set -g fish_color_escape brcyan
      set -g fish_color_history_current --bold
      set -g fish_color_host cyan
      set -g fish_color_host_remote yellow
      set -g fish_color_normal normal
      set -g fish_color_operator brcyan
      set -g fish_color_param cyan
      set -g fish_color_quote yellow
      set -g fish_color_redirection 'cyan --bold'
      set -g fish_color_search_match 'white --background=brblack'
      set -g fish_color_selection 'white --bold --background=brblack'
      set -g fish_color_status red
      set -g fish_color_user brgreen
      set -g fish_color_valid_path --underline
      set -g fish_pager_color_completion normal
      set -g fish_pager_color_description 'yellow -i'
      set -g fish_pager_color_prefix 'normal --bold --underline'
      set -g fish_pager_color_progress 'brwhite --background=cyan'
      set -g fish_pager_color_selected_background -r

      # Prompt settings
      set -g fish_prompt_pwd_dir_length 0
      set -g fish_color_hostname cyan

      # Git prompt settings
      set -g __fish_git_prompt_show_informative_status 1
      set -g __fish_git_prompt_showuntrackedfiles 1
      set -g __fish_git_prompt_color_branch 'magenta --bold'
      set -g __fish_git_prompt_showupstream informative
      set -g __fish_git_prompt_char_upstream_ahead "↑"
      set -g __fish_git_prompt_char_upstream_behind "↓"
      set -g __fish_git_prompt_char_upstream_prefix ""
      set -g __fish_git_prompt_char_stagedstate "●"
      set -g __fish_git_prompt_char_dirtystate "✚"
      set -g __fish_git_prompt_char_untrackedfiles "…"
      set -g __fish_git_prompt_char_conflictedstate "✖"
      set -g __fish_git_prompt_char_cleanstate "✔"
      set -g __fish_git_prompt_color_dirtystate \#afff5f
      set -g __fish_git_prompt_color_stagedstate yellow
      set -g __fish_git_prompt_color_invalidstate red
      set -g __fish_git_prompt_color_untrackedfiles $fish_color_normal
      set -g __fish_git_prompt_color_cleanstate 'green --bold'

      # Kitty keyboard protocol escape sequences (macOS)
      bind \e\[102\;9u 'forward-word' # command + f
      bind \e\[46\;9u 'history-token-search-backward' # command + .
    '';

    functions = {
      # macOS locale settings
      darwin_locale = {
        body = ''
          set -g LANG en_US.UTF-8
          set -x LC_ALL en_US.UTF-8
          set -x LC_CTYPE en_US.UTF-8
        '';
      };

      # Directory navigation shortcuts
      "1.." = { body = "cd ../"; };
      "2.." = { body = "cd ../../"; };
      "3.." = { body = "cd ../../../"; };
      "4.." = { body = "cd ../../../../"; };
      "5.." = { body = "cd ../../../../../"; };
      "6.." = { body = "cd ../../../../../../"; };
      "7.." = { body = "cd ../../../../../../../"; };
      "8.." = { body = "cd ../../../../../../../../"; };
      "9.." = { body = "cd ../../../../../../../../../"; };

      # Custom prompt
      fish_prompt = {
        description = "Write out the prompt";
        body = ''
          set -l last_status $status

          if not set -q __fish_prompt_normal
            set -g __fish_prompt_normal (set_color normal)
          end

          if not set -q __fish_prompt_hostname
            set -g __fish_prompt_hostname (hostname -s)
          end
          set_color $fish_color_hostname
          printf "$__fish_prompt_hostname "
          set_color normal

          set_color $fish_color_cwd
          echo -n (prompt_pwd)
          set_color normal

          printf '%s ' (__fish_git_prompt)

          if not test $last_status -eq 0
            set_color -o $fish_color_error
          else
            set_color -o green
          end
          printf '$ '

          set_color normal
        '';
      };

      # Custom pwd display
      prompt_pwd = {
        description = "Print the current working directory, shortened to fit the prompt";
        body = ''
          if test "$PWD" != "$HOME"
            printf "%s" (echo $PWD | sed -e 's|/private||' -e "s|^$HOME|~|")
          else
            echo '~'
          end
        '';
      };

      # User key bindings
      fish_user_key_bindings = {
        body = ''
          bind \ce 'accept-autosuggestion execute'
          bind \cbackspace 'backward-kill-word'
          bind \cleft 'backward-word'
          bind \cright 'forward-word'
          bind \cc 'echo; commandline ""; commandline -f repaint'
        '';
      };

      # Git branch cleanup
      git_clean_branches = {
        body = ''
          set base_branch develop

          git checkout $base_branch
          git fetch -p

          set local
          for f in (git branch --merged $base_branch | grep -v "\(master\|$base_branch\|\*\)" | awk '/\s*\w*\s*/ {print $1}')
            set local $local $f
          end

          set remote
          for f in (git branch -r | xargs basename)
            set remote $remote $f
          end

          for f in $local
            echo $remote | grep --quiet "\s$f\s"
            if [ $status -gt 0 ]
              git branch -d $f
            end
          end
        '';
      };

      # File growth speed monitor
      speed = {
        body = ''
          while true
            set old (du -sk $argv | cut -d"/" -f1 | cut -f1)
            sleep 1
            set new (du -sk $argv | cut -d"/" -f1 | cut -f1)
            set spd (math "$new - $old")
            set size (du -sh $argv | cut -d"/" -f1 | cut -f1)
            echo "$spd KB/s - $size"
          end
        '';
      };

      # Archive extractor
      x = {
        body = ''
          if test -z $argv
            echo "Error: No file specified."
            return 1
          end
          if test -e $argv
            for f in $argv
              switch "$f"
                case '*.tar.bz2'
                  tar xvjf $f
                case '*.tar.gz'
                  tar xvzf $f
                case '*.bz2'
                  bunzip2 $f
                case '*.rar'
                  unrar x $f
                case '*.gz'
                  gunzip $f
                case '*.tar'
                  tar xvf $f
                case '*.tbz2'
                  tar xvjf $f
                case '*.tgz'
                  tar xvzf $f
                case '*.zip'
                  unzip $f
                case '*.Z'
                  uncompress $f
                case '*.7z'
                  7z x $f
                case '*'
                  echo "'$f' cannot be extracted via x"
              end
            end
          else
            echo "'$argv' is not a valid file"
          end
        '';
      };
    };
  };
}
