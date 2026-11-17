{ ... }:

{
  imports = [
    ./resolved.nix
    ./timeshift.nix
  ];

  system-manager.allowAnyDistro = true;
}
