{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  inherit (import ./sockets.nix { inherit cfg pkgs; }) sandboxSocket socketBridge;
  ollama = "127.0.0.1:${toString cfg.ports.ollama}";
  filter = "127.0.0.1:${toString cfg.ports.filter}";
  # Path filter in front of Ollama for the bwrap sandbox
  # (oc-ollama.socket -> oc-ollama@ -> here). Only the chat API: no /api/pull,
  # /api/delete, /api/create, /api/generate and so on. Which model gets loaded
  # is in the body and not filtered here.
  caddyfile = pkgs.writeText "ollama-filter.Caddyfile" ''
    {
    	admin off
    	auto_https off
    	persist_config off
    }

    http://${filter} {
    	bind 127.0.0.1
    	@chat {
    		method POST
    		path /v1/chat/completions
    	}
    	@models {
    		method GET
    		path /v1/models
    	}
    	handle @chat {
    		reverse_proxy ${ollama}
    	}
    	handle @models {
    		reverse_proxy ${ollama}
    	}
    	respond 403
    }
  '';
in
{
  config = lib.mkIf cfg.enable {
    systemd.services.ollama-filter = {
      description = "Path filter in front of Ollama for the opencode sandbox (${filter})";
      after = [ "network.target" "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      environment = {
        XDG_DATA_HOME = "/var/lib/ollama-filter";
        XDG_CONFIG_HOME = "/var/lib/ollama-filter";
      };
      serviceConfig = {
        ExecStart = "${pkgs.caddy}/bin/caddy run --adapter caddyfile --config ${caddyfile}";
        DynamicUser = true;
        StateDirectory = "ollama-filter";
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        CapabilityBoundingSet = "";
        RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        IPAddressDeny = "any";
        IPAddressAllow = "localhost";
        Restart = "on-failure";
      };
    };

    systemd.sockets.oc-ollama = sandboxSocket "${cfg.socketDir}/ollama.sock" 16 // {
      description = "Ollama socket for the opencode sandbox (chat API only, through ollama-filter)";
    };
    systemd.services."oc-ollama@" = socketBridge filter // {
      description = "Bridge sandbox socket -> ollama-filter ${filter}";
      requires = [ "ollama-filter.service" ];
      after = [ "ollama-filter.service" ];
    };
  };
}
