{ config, ... }:

{
  sops.secrets."atuin/sync_address" = { sopsFile = ../../../secrets/atuin.yaml; };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      enter_accept = true;
      search_mode = "fuzzy";
      sync.records = true;
      daemon = {
        enabled = true;
        autostart = true;
      };
      ai.enabled = true;
    };
  };

  programs.fish.shellInit = ''
    set -gx ATUIN_SYNC_ADDRESS (cat ${config.sops.secrets."atuin/sync_address".path})
  '';
}
