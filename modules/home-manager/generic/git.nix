{ pkgs, ... }:

{
  programs.git = {
    enable = true;
    settings = {
      core.editor = "nvim";
      push.autoSetupRemote = true;
      init.defaultBranch = "master";
      alias = {
      co = "checkout";
      ci = "commit";
      cm = "commit";
      st = "status";
      ad = "add";
      df = "diff";
      dfc = "diff --cached";
      br = "branch";
      lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
      lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
      subup = "submodule update --init --recursive";
      subst = "submodule status --recursive";
      lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };
}
