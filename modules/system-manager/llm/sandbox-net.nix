{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  inherit (import ./sockets.nix { inherit cfg pkgs; }) sandboxSocket socketBridge;
  proxy = "127.0.0.1:${toString cfg.ports.proxy}";
  etcPath = lib.removePrefix "/etc/";
  # Egress lock for the agent user outside the sandbox (the sandbox itself has
  # its own network namespace without a route): only the local proxy. Own table,
  # leaves Docker's and other tables alone.
  rules = pkgs.writeText "oc-sandbox.nft" ''
    destroy table inet oc_sandbox
    table inet oc_sandbox {
      chain output {
        type filter hook output priority filter; policy accept;
        meta skuid "${cfg.agentUser}" ip daddr 127.0.0.1 tcp dport ${toString cfg.ports.proxy} accept
        meta skuid "${cfg.agentUser}" limit rate 6/minute log prefix "oc-sandbox drop: " level warn
        meta skuid "${cfg.agentUser}" counter drop
      }
    }
  '';
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.oc-nft = {
      description = "nftables egress lock for ${cfg.agentUser} (opencode sandbox)";
      wants = [ "network-pre.target" ];
      before = [ "network-pre.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft -f ${rules}";
        ExecStop = "${pkgs.nftables}/bin/nft destroy table inet oc_sandbox";
      };
    };

    systemd.sockets.oc-proxy = sandboxSocket "${cfg.socketDir}/proxy.sock" 64 // {
      description = "Egress proxy socket for the opencode sandbox";
    };
    systemd.services."oc-proxy@" = socketBridge proxy // {
      description = "Bridge sandbox socket -> tinyproxy ${proxy}";
      requires = [ "tinyproxy.service" ];
      after = [ "tinyproxy.service" ];
    };

    environment.etc = {
      # tinyproxy is the Arch package; the sandbox reaches it only through
      # proxy.sock. HTTPS tunnels only, only hosts from the allowlist, which
      # oc-net builds from base.filter plus open grants.
      "tinyproxy/tinyproxy.conf" = {
        replaceExisting = true;
        text = ''
          User tinyproxy
          Group tinyproxy
          Port ${toString cfg.ports.proxy}
          Listen 127.0.0.1
          BindSame no
          Timeout 600
          MaxClients 50

          Syslog On
          LogLevel Info
          PidFile "/run/tinyproxy/tinyproxy.pid"

          Allow 127.0.0.1
          DisableViaHeader Yes

          ConnectPort 443
          Filter "${cfg.sandboxNetDir}/proxy.filter"
          FilterType fnmatch
          FilterDefaultDeny Yes
        '';
      };
      # On start only the base allowlist (open grants do not survive a restart).
      "systemd/system/tinyproxy.service.d/oc-sandbox.conf".text = ''
        [Service]
        ExecStartPre=${cfg.binDir}/oc-net reset --no-reload
      '';
      # Always allowed (fnmatch, exact host). `oc-net open` grants registries for a while.
      "${etcPath cfg.sandboxNetDir}/base.filter" = {
        replaceExisting = true;
        text = ''
          openrouter.ai
        '';
      };
    };
  };
}
