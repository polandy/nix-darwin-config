{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [ "~/.colima/ssh_config" ];
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
    } // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      UseKeychain = "yes";
    };
  };
}
