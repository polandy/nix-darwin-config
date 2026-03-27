{ ... }:

{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    settings = {
      # Two-line prompt:
      # ~/project  main ●2 …1   2s
      # ❯
      format = ''
        $hostname$directory$git_branch$git_status$nix_shell$cmd_duration
        $character'';

      right_format = "$time";
      add_newline = true;

      character = {
        success_symbol = "[❯](bold green)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold yellow)";
      };

      os.disabled = true;

      hostname = {
        ssh_only = false;
        style = "bold cyan";
        format = "[$hostname]($style) ";
        trim_at = ".";
      };

      directory = {
        format = "[$path$read_only]($style) ";
        style = "bold cyan";
        truncation_length = 4;
        truncate_to_repo = true;
        read_only = " 󰌾";
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        format = "([$all_status$ahead_behind]($style) )";
        style = "bold yellow";
        conflicted = "✖";
        ahead = "↑\${count}";
        behind = "↓\${count}";
        diverged = "↕";
        untracked = "…";
        stashed = "󰏗";
        modified = "✚";
        staged = "●";
        renamed = "»";
        deleted = "✘";
      };

      nix_shell = {
        symbol = "󱄅 ";
        style = "bold blue";
        format = "[$symbol$state]($style) ";
        impure_msg = "";
        pure_msg = "pure";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style) ";
        style = "bold red";
      };

      time = {
        disabled = false;
        format = "[$time]($style)";
        style = "dimmed white";
        time_format = "%H:%M";
      };

      aws.disabled = true;
      gcloud.disabled = true;
      azure.disabled = true;
      terraform.disabled = true;
      kubernetes.disabled = true;
    };
  };
}
