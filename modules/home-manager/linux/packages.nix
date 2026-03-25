{ pkgs, ... }: {
  home.packages = with pkgs; [
    just
    p7zip
    bind
    dust
    imagemagick
    mc
    hugo
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
    # photography
    darktable
    digikam
    hugin

    # beets
    beets

    # base-ui
    firefox
    chromium
    mpv
    vlc
    ffmpeg
    meld
    android-tools
    geeqie
    evince
  ];
}
