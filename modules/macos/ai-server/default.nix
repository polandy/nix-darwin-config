# Headless AI inference server: keeps the Mac awake and reachable, raises the GPU
# wired-memory limit, and runs an MLX model server plus an Anthropic-compatible
# LiteLLM proxy in front of it, so Claude Code can use the local model.
# See docs/dev/ai-server.md.
{ config, pkgs, lib, ... }:

let
  cfg = config.my.aiServer;
  user = config.system.primaryUser;
  home = config.users.users.${user}.home;

  # Claude Code speaks the Anthropic Messages API, mlx_lm.server speaks the OpenAI
  # API. LiteLLM translates between them; "*" routes every model name Claude Code
  # asks for (claude-sonnet-..., claude-haiku-...) to the one local model.
  litellmConfig = (pkgs.formats.yaml { }).generate "litellm-config.yaml" {
    model_list = [{
      model_name = "*";
      litellm_params = {
        model = "openai/${cfg.model}";
        api_base = "http://127.0.0.1:${toString cfg.mlx.port}/v1";
        api_key = "none";
      };
    }];
    litellm_settings.drop_params = true;
  };
in
{
  options.my.aiServer = {
    enable = lib.mkEnableOption "headless MLX inference server";

    gpuWiredLimitMb = lib.mkOption {
      type = lib.types.ints.positive;
      description = ''
        Value for `sysctl iogpu.wired_limit_mb`: how much unified memory the GPU may
        wire. Leave enough for macOS (~24-32 GB on a 256 GB machine).
      '';
    };

    model = lib.mkOption {
      type = lib.types.str;
      example = "mlx-community/Qwen3-235B-A22B-4bit";
      description = ''
        Hugging Face repo of the MLX model served by default. Downloaded into
        ~/.cache/huggingface on first start.
      '';
    };

    mlx = {
      # mlx from nixpkgs is built without Metal (the Metal compiler is not
      # open source, see nixpkgs mlx/default.nix), so it would run on the CPU only.
      # uvx runs the PyPI wheels, which include Metal; pin the version here.
      version = lib.mkOption {
        type = lib.types.str;
        default = "0.31.3";
        description = "mlx-lm version from PyPI.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "--max-tokens" "32768" ];
        description = "Extra arguments for mlx_lm.server.";
      };
    };

    proxy = {
      # Loopback only: neither server has authentication. Expose it on the
      # tailnet with `tailscale serve` (see docs/dev/ai-server.md).
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 4000;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Never sleep, come back after a power cut, wake on LAN.
    # FileVault blocks an unattended reboot at the pre-boot unlock screen.
    power = {
      sleep = {
        computer = "never";
        display = "never";
        harddisk = "never";
      };
      restartAfterPowerFailure = true;
    };
    networking.wakeOnLan.enable = true;

    # Remote Login, and Tailscale as a root daemon: the Tailscale GUI app only
    # runs after a user logs in, which never happens on a headless box.
    services.openssh.enable = true;
    services.tailscale.enable = true;

    environment.systemPackages = [ pkgs.uv pkgs.litellm ];

    # System daemons rather than user agents: user agents only start on a GUI
    # login, daemons start at boot.
    launchd.daemons = {
      # sysctl values are not persistent, so reapply at every boot.
      gpu-wired-limit.serviceConfig = {
        ProgramArguments = [ "/usr/sbin/sysctl" "iogpu.wired_limit_mb=${toString cfg.gpuWiredLimitMb}" ];
        RunAtLoad = true;
      };

      mlx-server.serviceConfig = {
        UserName = user;
        ProgramArguments = [
          "${pkgs.uv}/bin/uvx"
          "--from"
          "mlx-lm==${cfg.mlx.version}"
          "mlx_lm.server"
          "--model"
          cfg.model
          "--host"
          "127.0.0.1"
          "--port"
          (toString cfg.mlx.port)
        ] ++ cfg.mlx.extraArgs;
        EnvironmentVariables.HOME = home;
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${home}/Library/Logs/mlx-server.log";
        StandardErrorPath = "${home}/Library/Logs/mlx-server.log";
      };

      litellm.serviceConfig = {
        UserName = user;
        ProgramArguments = [
          "${pkgs.litellm}/bin/litellm"
          "--config"
          "${litellmConfig}"
          "--host"
          cfg.proxy.host
          "--port"
          (toString cfg.proxy.port)
        ];
        EnvironmentVariables.HOME = home;
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "${home}/Library/Logs/litellm.log";
        StandardErrorPath = "${home}/Library/Logs/litellm.log";
      };
    };
  };
}
