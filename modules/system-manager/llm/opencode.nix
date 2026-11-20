# opencode config for the sandbox (not a module, imported by sandbox.nix).
# Both directories live in the store; oc-sandbox mounts them read-only, so the
# agent cannot change its own rules.
{ cfg, lib, pkgs }:

let
  # Where oc-sandbox mounts the config inside the sandbox.
  mount = "${cfg.agentHome}/.config/opencode";
  localModels = lib.filterAttrs (_: m: lib.hasPrefix "ollama/" m.id) cfg.models;
  cloudModels = lib.filterAttrs (_: m: lib.hasPrefix "openrouter/" m.id) cfg.models;

  # OpenRouter provider routing; no automatic model fallback (policy: fallback none).
  routing = {
    require_parameters = true;
    quantizations = [ "fp4" "nvfp4" "fp8" ];
    allow_fallbacks = true;
  };
  dataPolicy = {
    zdr = {
      data_collection = "deny";
      zdr = true;
    };
    public.data_collection = "allow";
  };

  # Permissions and the rest come from sandbox/opencode/opencode.json; the models
  # and the sandbox's Ollama bridge (inner) come from the llm options.
  settings = data: lib.recursiveUpdate (lib.importJSON ./sandbox/opencode/opencode.json) {
    model = cfg.models.cloud.id;
    provider.ollama = {
      options.baseURL = "http://127.0.0.1:${toString cfg.ports.ollama}/v1";
      models = lib.mapAttrs'
        (_: m: lib.nameValuePair (lib.removePrefix "ollama/" m.id) {
          name = if m.label == null then m.id else m.label;
          tool_call = true;
          limit = {
            inherit (m) context;
            output = 16384;
          };
        })
        localModels;
    };
    # v2 key: opencode 2.2.7 drops "body" under the legacy "provider" key.
    providers.openrouter = {
      body.provider = routing // dataPolicy.${data};
      models = lib.mapAttrs'
        (_: m: lib.nameValuePair (lib.removePrefix "openrouter/" m.id) {
          limit = {
            inherit (m) context;
            output = 16384;
          };
          body.provider.max_price = {
            prompt = 0.2;
            completion = 0.8;
          };
        })
        cloudModels;
    };
  };

  # Per-repo config (OPENCODE_CONFIG), named after the profile in oc-sandbox.
  repoProfiles = {
    skipper-cd.permissions = map (cmd: { action = "shell"; resource = cmd; effect = "allow"; }) [
      "go build *"
      "go test *"
      "go vet *"
      "make lint"
    ];
    # Pilot clones stella-*: pilot rules before the repo's own instructions.
    stella-pilot.instructions = [
      "${mount}/pilot-rules.md"
      "/work/AGENTS.md"
      "/work/CLAUDE.md"
    ];
  };
  json = name: value: pkgs.writeText "${name}.json" (builtins.toJSON value);
in
{
  inherit mount;

  config = pkgs.runCommand "oc-sandbox-opencode" { nativeBuildInputs = [ pkgs.jq ]; } ''
    mkdir $out
    cp -r ${./sandbox/opencode}/. $out/
    chmod u+w $out
    rm $out/opencode.json
    jq . ${json "opencode" (settings "zdr")} > $out/opencode.json
  '';

  # Variant for public repos (llm.sandbox.publicRepos), picked by oc-config.
  public = pkgs.runCommand "oc-sandbox-opencode-public.json" { nativeBuildInputs = [ pkgs.jq ]; } ''
    jq . ${json "opencode" (settings "public")} > $out
  '';

  repos = pkgs.runCommand "oc-sandbox-repos" { nativeBuildInputs = [ pkgs.jq ]; } (
    lib.concatStrings (
      [ "mkdir $out\n" ]
      ++ lib.mapAttrsToList (n: v: "jq . ${json n v} > $out/${n}.json\n") repoProfiles
    )
  );
}
