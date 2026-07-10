{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = pkgs.lib.optionals pkgs.stdenv.isDarwin [ "~/.colima/ssh_config" ];
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
    } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      UseKeychain = "yes";
    };
  };
}
