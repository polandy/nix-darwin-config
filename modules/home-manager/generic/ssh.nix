{ pkgs, ... }:

{
  home.packages = [ pkgs.mosh ];

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = pkgs.lib.optionals pkgs.stdenv.isDarwin [ "~/.colima/ssh_config" ];
    settings."*" = {
      AddKeysToAgent = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
    } // pkgs.lib.optionalAttrs pkgs.stdenv.isDarwin {
      # UseKeychain is Apple-only; IgnoreUnknown keeps non-Apple ssh builds
      # (e.g. the openssh that nixpkgs' mosh calls) from choking on it.
      IgnoreUnknown = "UseKeychain";
      UseKeychain = "yes";
    };
  };
}
