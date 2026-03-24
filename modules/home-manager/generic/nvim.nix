{ pkgs, ... }:

{
  xdg.configFile."nvim".source = ./nvim;

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      # LSP servers
      gopls
      pyright
      typescript-language-server
      lua-language-server

      # Go tools (goimports, etc.)
      gotools
      gofumpt

      # Formatters / linters
      stylua
      shellcheck
      shfmt
      python3Packages.flake8

      # Telescope
      ripgrep
      fd

      # lazygit integration
      lazygit

      # Node runtime (required by tsserver)
      nodejs
    ];
  };
}
