{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = pkgs.lib.optionals pkgs.stdenv.isDarwin [ "~/.colima/ssh_config" ];
    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        extraOptions = pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
          UseKeychain = "yes";
        };
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
