{ ... }: {
  imports = [
    ./gtk.nix
    ./mc.nix
    ./metapac
    ./mimeapps.nix
    ./wireplumber.nix
    ./wayland
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or "") [ "zsh-abbr" ];

  services.ssh-agent.enable = true;
}
