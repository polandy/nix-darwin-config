{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  port = toString cfg.ports.ollama;
  # Ollama has no auth and binds 0.0.0.0, so the port is limited here instead:
  # localhost, the path-filtering Caddy of the Docker LLM sandbox and the hosts
  # in the `allowed` set. Own table, so Docker's and oc-sandbox's tables stay
  # untouched.
  # Caddy (container ollama-proxy) has the fixed address 10.111.34.2 on its own
  # internal Docker network ollama-up (10.111.34.0/29, outside Docker's address
  # pools; see ai-sandbox sandbox/run-agent.sh). Not all of 172.16.0.0/12: agent
  # containers would reach Ollama past Caddy's filter via their bridge gateway.
  # Drop the Caddy rule once the Docker sandbox is gone (bwrap sandbox reaches
  # Ollama over localhost).
  # LAN hosts stay out of this public repo: a host-local file, e.g.
  # /etc/ollama-lan/allowed.nft containing
  #   add element inet ollama_lan allowed { <lan-ip> }
  # None is needed today. The glob include is a no-op when no file exists.
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
        tcp dport ${port} ip saddr 10.111.34.2 accept
        tcp dport ${port} ip saddr @allowed accept
        tcp dport ${port} counter drop
      }
    }
    include "/etc/ollama-lan/*.nft"
  '';
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.ollama-lan-firewall = {
      description = "Limit Ollama port ${port} to localhost, the sandbox Caddy and allowed LAN hosts";
      wantedBy = [ "system-manager.target" ];
      before = [ "ollama.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft -f ${rules}";
        ExecStop = "${pkgs.nftables}/bin/nft delete table inet ollama_lan";
      };
    };
  };
}
