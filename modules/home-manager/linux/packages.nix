{ pkgs, ... }: {
  home.packages = with pkgs; [
    just
    bat
    ripgrep
    fd
    fzf
    jq
    mise
    zoxide
    vivid
eza
    tmux
    ncdu
    tree
    htop
    aria2
    mosh
    rsync
    rclone
    restic
    yt-dlp
    neovim
  ];
}
