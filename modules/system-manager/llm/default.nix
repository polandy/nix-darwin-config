{ config, lib, ... }:

let
  inherit (lib) mkOption types;
  cfg = config.llm;
in
{
  # Local LLM setup on coolermaster: Ollama limits, the bwrap sandbox tool
  # (oc-sandbox, its opencode config) and its network access (egress proxy,
  # chat-only Ollama socket), the GPU lock and the jobs (bench, pilot) that run
  # as the agent user. Values shared between the files below are the options here.
  imports = [
    ./ollama.nix
    ./firewall.nix
    ./filter.nix
    ./sandbox.nix
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

    agentHome = mkOption {
      type = types.str;
      default = "/home/${cfg.agentUser}";
      defaultText = lib.literalExpression ''"/home/''${config.llm.agentUser}"'';
      description = "Agent user's home; the sandbox mounts its per-repo state and the opencode config below it.";
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

    binDir = mkOption {
      type = types.str;
      default = "/usr/local/bin";
      description = ''
        Stable paths (links into the store) for tools called by name: by sudoers
        rules, by the jobs, by the orchestrator over ssh and inside the sandbox.
      '';
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

    sandbox = {
      keyFile = mkOption {
        type = types.str;
        example = "/home/aiagent/.openrouter-apikey";
        description = ''
          Host-local file with the OpenRouter key, readable only by the agent user.
          Only its path is configured; the key never enters the Nix store.
        '';
      };

      repos = mkOption {
        type = types.listOf types.str;
        default = [ "skipper-cd" "Stella" "framehive" "honeycomb" ];
        description = ''
          Fixed clones under agentDir the sandbox accepts (oc-sandbox, oc-outbox).
          Throwaway clones bench-* and stella-* are added by oc-sandbox itself.
        '';
      };
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
          label = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Display name in opencode (local models).";
          };
        };
      });
      default = {
        cloud.id = "openrouter/z-ai/glm-5.3-flash";
        local = {
          id = "ollama/bench-gemma4-26b";
          context = 65536;
          label = "Gemma 4 26B-A4B (64k)";
        };
        local-128k = {
          id = "ollama/bench-gemma4-26b-128k";
          context = 131072;
          label = "Gemma 4 26B-A4B (128k, t5-like tasks only)";
        };
      };
      description = "Model classes of the policy, also used by the job configs and the sandbox (allowed models, default = cloud).";
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
