{ pkgs, ... }:

{
  xdg.configFile."nvim".source = ./nvim;

  programs.neovim = {
    enable = true;
    withRuby = false;
    withPython3 = false;
    extraPackages = with pkgs; [
      gopls
      pyright
      typescript-language-server
      lua-language-server

      gotools
      gofumpt

      stylua
      shellcheck
      shfmt
      python3Packages.flake8

      ripgrep
      fd

      lazygit

      # required by tsserver
      nodejs
    ];
  };
}
