{ config, pkgs, lib, ... }:

{
  sops.age.keyFile = "/Users/andy/.config/sops/age/keys.txt";

  sops.secrets."syncthing/homelab_id" = { sopsFile = ../../secrets/syncthing.yaml; };
  sops.secrets."syncthing/ipm_id" = { sopsFile = ../../secrets/syncthing.yaml; };
  sops.secrets."syncthing/pixel9_id" = { sopsFile = ../../secrets/syncthing.yaml; };

  services.syncthing = {
    enable = true;
    settings.folders."logseq-private" = {
      path = "/Users/andy/Syncthing/logseq-private";
      ignorePerms = false;
      # devices intentionally omitted — configured via activation script
    };
  };

  home.activation.syncthingDevices = lib.hm.dag.entryAfter [ "setupSecrets" ] ''
    run ${pkgs.bash}/bin/bash ${pkgs.writeScript "syncthing-devices" ''
      #!/usr/bin/env bash
      CONFIG="$HOME/Library/Application Support/Syncthing/config.xml"
      [ -f "$CONFIG" ] || exit 0

      API_KEY=$(grep -oE '<apikey>[^<]+</apikey>' "$CONFIG" | sed 's|<[^>]*>||g')
      [ -n "$API_KEY" ] || exit 0
      BASE="http://127.0.0.1:8384/rest"
      HEADER="X-API-Key: $API_KEY"

      ${pkgs.curl}/bin/curl -sf -H "$HEADER" "$BASE/system/ping" >/dev/null 2>&1 || exit 0

      add_device() {
        local id="$1" name="$2"
        existing=$(${pkgs.curl}/bin/curl -sf -H "$HEADER" "$BASE/config/devices" \
          | ${pkgs.jq}/bin/jq -r '.[].deviceID')
        echo "$existing" | grep -q "$id" && return 0
        ${pkgs.curl}/bin/curl -sf -X POST -H "$HEADER" -H "Content-Type: application/json" \
          -d "{\"deviceID\":\"$id\",\"name\":\"$name\",\"autoAcceptFolders\":false}" \
          "$BASE/config/devices"
      }

      add_device "$(cat ${config.sops.secrets."syncthing/homelab_id".path})" "homelab"
      add_device "$(cat ${config.sops.secrets."syncthing/ipm_id".path})"     "ipm"
      add_device "$(cat ${config.sops.secrets."syncthing/pixel9_id".path})"  "pixel9"
    ''}
  '';
}
