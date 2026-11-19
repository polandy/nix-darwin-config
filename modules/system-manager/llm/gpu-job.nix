{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  vars = {
    inherit (cfg) agentUser agentDir gpuLock group jobsDir;
    ollama = "127.0.0.1:${toString cfg.ports.ollama}";
    pilotModel = lib.removePrefix "ollama/" cfg.models.local.id;
  };
  # scripts/<name>.sh with @var@ filled in from `vars`
  script = name: args: pkgs.writeShellApplication ({
    inherit name;
    text = builtins.replaceStrings
      (map (n: "@${n}@") (lib.attrNames vars))
      (lib.attrValues vars)
      (builtins.readFile ./scripts/${name}.sh);
  } // args);

  llm-gpu = script "llm-gpu" {
    runtimeInputs = [ pkgs.coreutils pkgs.util-linux ];
    # Exit codes are part of the interface (75 = deferred), no errexit.
    bashOptions = [ "nounset" "pipefail" ];
  };
  llm-job = script "llm-job" {
    runtimeInputs = [ pkgs.coreutils ];
  };
  llm-job-unload = script "llm-job-unload" {
    runtimeInputs = [ pkgs.coreutils pkgs.curl pkgs.gnused pkgs.jq pkgs.util-linux ];
    bashOptions = [ "nounset" "pipefail" ];
  };
in
{
  config = lib.mkIf cfg.enable {
    # userborn keeps members it did not add, so existing memberships survive.
    users.groups.${cfg.group}.members = [ cfg.ownerUser cfg.agentUser ];

    systemd.tmpfiles.rules = [
      "f ${cfg.gpuLock} 0660 root ${cfg.group} -"
      # Bench, pilot (as the agent user) and the orchestrator (ssh) call it by name.
      "L+ ${cfg.binDir}/llm-gpu - - - - ${llm-gpu}/bin/llm-gpu"
    ];

    systemd.services."llm-job@" = {
      description = "Local LLM job %i (${cfg.jobsDir}/%i.env, as ${cfg.agentUser})";
      after = [ "ollama.service" "oc-ollama.socket" ];
      wants = [ "oc-ollama.socket" ];
      unitConfig.ConditionPathExists = "${cfg.jobsDir}/%i.env";
      # Bench and pilot call host tools (git, bwrap, oc-sandbox, pacman) by name.
      enableDefaultPath = false;
      serviceConfig = {
        Type = "exec";
        User = cfg.agentUser;
        Group = cfg.agentUser;
        SupplementaryGroups = cfg.group;
        Slice = "llm.slice";
        EnvironmentFile = "${cfg.jobsDir}/%i.env";
        ExecStart = "${llm-job}/bin/llm-job %i";
        ExecStopPost = "+${llm-job-unload}/bin/llm-job-unload %i";
        # 75 = deferred (GPU busy): no failure, but in the journal and in the run logs.
        SuccessExitStatus = 75;
        # Upper bound for the whole job; the runs have their own timeout.
        RuntimeMaxSec = "12h";
        KillMode = "control-group";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
