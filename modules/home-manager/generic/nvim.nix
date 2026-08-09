{ pkgs, ... }:

{
  xdg.configFile."nvim".source = ./nvim;

  programs.neovim = {
    enable = true;

    # Upstream flipped these defaults to false; home.stateVersion (24.05) still
    # pins us to the legacy `true`, which emits a warning on every rebuild.
    # Nothing under ./nvim uses the Ruby or Python3 remote host, so adopt the
    # new default rather than silencing the warning by opting back in.
    withRuby = false;
    withPython3 = false;

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
