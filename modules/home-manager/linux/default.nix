{ ... }: {
  imports = [
    ./packages.nix
    ./beets.nix
    ./gtk.nix
    ./mc.nix
    ./mimeapps.nix
    ./wireplumber.nix
    ./wayland
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or "") [ "zsh-abbr" ];

  services.ssh-agent.enable = true;
}
