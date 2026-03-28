{ ... }: {
  imports = [
    ./packages.nix
    ./wayland
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkg.pname or "") [ "zsh-abbr" ];
}
