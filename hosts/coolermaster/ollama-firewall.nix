{ pkgs, ... }:

let
  # Ollama has no auth and binds 0.0.0.0, so the port is limited here instead:
  # localhost, Docker bridges (the LLM sandbox forwarder) and the hosts in the
  # `allowed` set. Own table, so Docker's and oc-sandbox's tables stay untouched.
  # The LAN addresses stay out of this public repo: they live in a host-local
  # file, e.g. /etc/ollama-lan/allowed.nft containing
  #   add element inet ollama_lan allowed { <nuc-ip> }
  # The glob include is a no-op when no file exists.
  rules = pkgs.writeText "ollama-lan.nft" ''
    destroy table inet ollama_lan
    table inet ollama_lan {
      set allowed {
        type ipv4_addr
        flags interval
      }
      chain input {
        type filter hook input priority filter; policy accept;
        tcp dport 11434 iif lo accept
        tcp dport 11434 ip saddr 172.16.0.0/12 accept
        tcp dport 11434 ip saddr @allowed accept
        tcp dport 11434 counter drop
      }
    }
    include "/etc/ollama-lan/*.nft"
  '';
in
{
  systemd.services.ollama-lan-firewall = {
    description = "Limit Ollama port 11434 to localhost, Docker and allowed LAN hosts";
    wantedBy = [ "system-manager.target" ];
    before = [ "ollama.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.nftables}/bin/nft -f ${rules}";
      ExecStop = "${pkgs.nftables}/bin/nft delete table inet ollama_lan";
    };
  };
}
