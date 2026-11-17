{ config, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/generic
    ../../modules/home-manager/generic/ssh.nix
    ../../modules/home-manager/linux
  ];

  xdg.configFile."hypr/host.lua".source = ./hyprland.lua;

  # Sunshine (Moonlight streaming host) ships its user unit via the Arch package (sunshine-git),
  # so only enable it here: the same symlink `systemctl --user enable` would create.
  # Its settings (sunshine.conf, apps.json) stay unmanaged; the web UI at https://localhost:47990 writes them.
  xdg.configFile."systemd/user/graphical-session.target.wants/app-dev.lizardbyte.app.Sunshine.service".source =
    config.lib.file.mkOutOfStoreSymlink "/usr/lib/systemd/user/app-dev.lizardbyte.app.Sunshine.service";
}
