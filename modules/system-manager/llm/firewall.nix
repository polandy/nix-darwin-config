{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  port = toString cfg.ports.ollama;
  allowDir = "/etc/ollama-lan";
  # Ollama has no auth and binds 0.0.0.0, so the port is limited here instead:
  # localhost and the hosts in the `allowed` set. Own table, so Docker's and
  # oc-sandbox's tables stay untouched. The bwrap sandbox reaches Ollama over
  # localhost through ollama-filter.
  # No address lives in this public repo. Other hosts (LAN, or a container such
  # as the Docker sandbox's Caddy) go into host-local files under
  # ${allowDir}, e.g. ${allowDir}/allowed.nft containing
  #   add element inet ollama_lan allowed { <ip> }
  # Default without such a file: localhost only. The glob include is a no-op
  # then, and the unit logs which files it loaded.
  rules = pkgs.writeText "ollama-lan.nft" ''
    destroy table inet ollama_lan
    table inet ollama_lan {
      set allowed {
        type ipv4_addr
        flags interval
      }
      chain input {
        type filter hook input priority filter; policy accept;
        tcp dport ${port} iif lo accept
        tcp dport ${port} ip saddr @allowed accept
        tcp dport ${port} counter drop
      }
    }
    include "${allowDir}/*.nft"
  '';
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.ollama-lan-firewall = {
      description = "Limit Ollama port ${port} to localhost and the host-local allowed hosts";
      wantedBy = [ "system-manager.target" ];
      before = [ "ollama.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft -f ${rules}";
        ExecStartPost = pkgs.writeShellScript "ollama-lan-firewall-report" ''
          shopt -s nullglob
          files=(${allowDir}/*.nft)
          if [ ''${#files[@]} -eq 0 ]; then
            echo "no host-local allow files in ${allowDir}: Ollama port ${port} is reachable from localhost only"
          else
            echo "host-local allow files: ''${files[*]}"
          fi
        '';
        ExecStop = "${pkgs.nftables}/bin/nft delete table inet ollama_lan";
      };
    };
  };
}
