{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.llm;
in
{
  # Local LLM setup on coolermaster: Ollama limits, the bwrap sandbox's network
  # access (egress proxy, chat-only Ollama socket), the GPU lock and the jobs
  # (bench, pilot) that run as the agent user. The sandbox tool itself
  # (oc-sandbox, oc-net, its opencode config) is still installed by ai-sandbox
  # install.sh. Values shared between the files below are the options here.
  imports = [
    ./ollama.nix
    ./firewall.nix
    ./filter.nix
    ./sandbox-net.nix
    ./gpu-job.nix
    ./jobs.nix
    ./policy.nix
  ];

  options.llm = {
    enable = lib.mkEnableOption "the local LLM setup (Ollama, sandbox network, GPU lock, jobs)";

    ownerUser = mkOption {
      type = types.str;
      default = "andy";
      description = "Owner account, member of the LLM group (reads pilot results, checks the GPU lock).";
    };

    agentUser = mkOption {
      type = types.str;
      default = "aiagent";
      description = "Existing account that runs the sandbox, bench and pilot. Not created here.";
    };

    group = mkOption {
      type = types.str;
      default = "llm";
      description = "Group for the GPU lock and the pilot results; members are the owner and the agent user.";
    };

    agentDir = mkOption {
      type = types.str;
      default = "/srv/aiagent";
      description = "Agent user's work area (bench and ai-sandbox clones, Stella mirror). Filled by hand.";
    };

    pilotOut = mkOption {
      type = types.str;
      default = "/srv/llm-pilot";
      description = "Pilot results, written by the agent user, readable for the group.";
    };

    jobsDir = mkOption {
      type = types.str;
      default = "/etc/llm-jobs";
      description = "Job configs for llm-job@<name>.service.";
    };

    gpuLock = mkOption {
      type = types.str;
      default = "/run/lock/llm-gpu";
      description = "flock file that serialises local GPU users (llm-gpu).";
    };

    socketDir = mkOption {
      type = types.str;
      default = "/run/oc-proxy";
      description = "Sockets the sandbox reaches the host through (egress proxy, Ollama filter).";
    };

    sandboxNetDir = mkOption {
      type = types.str;
      default = "/etc/oc-sandbox/net";
      description = "oc-net's directory: base.filter here, oc-net writes proxy.filter next to it.";
    };

    ports = {
      ollama = mkOption {
        type = types.port;
        default = 11434;
      };
      filter = mkOption {
        type = types.port;
        default = 11435;
        description = "ollama-filter (Caddy) on localhost, only the chat API.";
      };
      proxy = mkOption {
        type = types.port;
        default = 3128;
        description = "tinyproxy, the sandbox's egress proxy on localhost.";
      };
    };

    models = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          id = mkOption {
            type = types.str;
            description = "opencode model ID.";
          };
          context = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
        };
      });
      default = {
        cloud.id = "openrouter/z-ai/glm-5.3-flash";
        local = {
          id = "ollama/bench-gemma4-26b";
          context = 65536;
        };
        local-128k = {
          id = "ollama/bench-gemma4-26b-128k";
          context = 131072;
        };
      };
      description = "Model classes of the policy, also used by the job configs.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/etc/" cfg.jobsDir && lib.hasPrefix "/etc/" cfg.sandboxNetDir;
        message = "llm.jobsDir and llm.sandboxNetDir must be below /etc (environment.etc).";
      }
    ];
  };
}
