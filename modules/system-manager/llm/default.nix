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
    ./pr-broker.nix
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

      publicRepos = mkOption {
        type = types.listOf types.str;
        default = [ "skipper-cd" "Stella" "framehive" "honeycomb" ];
        description = ''
          Repos (of sandbox.repos) that are public on GitHub: OpenRouter may use providers that
          collect data for them. All others, and anything unknown, use ZDR endpoints only.
          Keep in sync with the GitHub visibility; remove a repo before it turns private.
        '';
      };

      github = {
        owner = mkOption {
          type = types.str;
          default = "polandy";
          description = "GitHub owner of sandbox.repos; the broker (oc-pr) pushes to <owner>/<repo>.";
        };

        tokenFile = mkOption {
          type = types.str;
          default = "/etc/oc-pr/github-token";
          description = ''
            Host-local file (root, 0600) with the broker's fine-grained GitHub token; systemd hands
            it to the broker as a credential. Never in the store, never in the sandbox.
          '';
        };

        reviewers = mkOption {
          type = types.listOf types.str;
          default = [ "polandy" ];
          description = "GitHub logins whose \"PR quality review\" comment counts for the broker's merge gate.";
        };

        branchPrefixes = mkOption {
          type = types.listOf types.str;
          default = [ "feat/" "fix/" "chore/" "docs/" "ci/" "refactor/" "test/" "perf/" "build/" ];
          description = "Branch prefixes the broker pushes and merges; anything else (gh-pages, release/*) is refused.";
        };
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
          routing = mkOption {
            type = types.attrsOf types.anything;
            default = { };
            description = "OpenRouter provider routing for this model (quantizations, max_price); replaces the shared default per key. The data policy cannot be overridden.";
          };
        };
      });
      default = {
        cloud = {
          id = "openrouter/z-ai/glm-5.3-flash";
          context = 200000;
        };
        cloud-fallback = {
          id = "openrouter/minimax/minimax-m3.1-flash";
          context = 200000;
        };
        gpt-sol = {
          id = "openrouter/openai/gpt-6.2-sol";
          context = 400000;
          routing = {
            quantizations = [ "fp8" "bf16" ];
            max_price = {
              prompt = 2.5;
              completion = 10;
            };
          };
        };
        kimi-pro = {
          id = "openrouter/moonshotai/kimi-k3.1-pro";
          context = 256000;
          routing = {
            quantizations = [ "int4" "fp4" "nvfp4" "fp8" ];
            max_price = {
              prompt = 1;
              completion = 4;
            };
          };
        };
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
        # Same 64k without the base's MTP draft model, which Ollama 0.40.11 does not fit into 16 GB.
        local-nodraft = {
          id = "ollama/bench-gemma4-26b-nodraft";
          context = 65536;
          label = "Gemma 4 26B-A4B (64k, no draft model)";
        };
        local-128k-nodraft = {
          id = "ollama/bench-gemma4-26b-128k-nodraft";
          context = 131072;
          label = "Gemma 4 26B-A4B (128k, no draft model)";
        };
        local-qwen3-coder-next-128k = {
          id = "ollama/bench-qwen3-coder-next-128k";
          context = 131072;
          label = "Qwen3-Coder-Next 80B-A3B (128k)";
        };
      };
      description = "Models offered by the sandbox (allowed models, default = cloud); policy.nix and the job configs pick their classes from them by name.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/etc/" cfg.jobsDir && lib.hasPrefix "/etc/" cfg.sandboxNetDir;
        message = "llm.jobsDir and llm.sandboxNetDir must be below /etc (environment.etc).";
      }
      {
        assertion = lib.all (r: lib.elem r cfg.sandbox.repos) cfg.sandbox.publicRepos;
        message = "llm.sandbox.publicRepos must be a subset of llm.sandbox.repos.";
      }
    ];
  };
}
