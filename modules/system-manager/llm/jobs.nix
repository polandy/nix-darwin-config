{ config, lib, ... }:

let
  cfg = config.llm;
  ollamaModel = class: lib.removePrefix "ollama/" cfg.models.${class}.id;
  bench = class: "${ollamaModel class}:latest ${toString cfg.models.${class}.context}";
  # Job configs for llm-job@<name>.service. Start (owner): systemctl start llm-job@<name>.
  # OLLAMA_KEEP_ALIVE=0 unloads the models after the job (owner decision 9.2 c).
  jobs = {
    # Stella pilot in path A (owner decision 2.2 a: Gemma 4 with 64k), results in
    # ${cfg.pilotOut}/runs. 45 min per run as in the Qwen run of path B, so the
    # series stay comparable.
    pilot-gemma4 = {
      JOB = "pilot";
      MODEL = ollamaModel "local";
      PILOT_TIMEOUT = "45m";
      OLLAMA_KEEP_ALIVE = 0;
    };
    # coding-model-bench bench/series.sh as the agent user with SANDBOX=1.
    bench-gemma4-64k = {
      JOB = "bench";
      SERIES = "gemma4-64k-sandbox ${bench "local"} t1-bugfix:1-2 t2-gitlab:1-2 t3-policy:1-2 t4-icons:1-2";
      TIMEOUT = 1500;
      EMPTY_RETRIES = 2;
      OLLAMA_KEEP_ALIVE = 0;
    };
    # The 128k option for t5 (owner decision 2.1 a).
    bench-gemma4-128k-t5 = {
      JOB = "bench";
      SERIES = "gemma4-128k-t5-sandbox ${bench "local-128k"} t5-orphans:1-6";
      TIMEOUT = 3600;
      EMPTY_RETRIES = 2;
      OLLAMA_KEEP_ALIVE = 0;
    };
  };
  envFile = env: lib.concatStrings (lib.mapAttrsToList (k: v: ''${k}="${toString v}"'' + "\n") env);
in
{
  config = lib.mkIf cfg.enable {
    environment.etc = lib.mapAttrs'
      (name: env: lib.nameValuePair "${lib.removePrefix "/etc/" cfg.jobsDir}/${name}.env" {
        text = envFile env;
      })
      jobs;

    systemd.tmpfiles.rules = [
      # Pilot results: the agent user writes, the owner reads through the group.
      "d ${cfg.pilotOut} 2750 ${cfg.agentUser} ${cfg.group} -"
    ];
  };
}
