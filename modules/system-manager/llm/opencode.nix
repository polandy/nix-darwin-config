# opencode config for the sandbox (not a module, imported by sandbox.nix).
# Both directories live in the store; oc-sandbox mounts them read-only, so the
# agent cannot change its own rules.
{ cfg, lib, pkgs }:

let
  # Where oc-sandbox mounts the config inside the sandbox.
  mount = "${cfg.agentHome}/.config/opencode";
  localModels = lib.filterAttrs (_: m: lib.hasPrefix "ollama/" m.id) cfg.models;
  cloudModels = lib.filterAttrs (_: m: lib.hasPrefix "openrouter/" m.id) cfg.models;
  permissions = import ./permissions.nix { inherit lib; };

  # OpenRouter provider routing; models with their own routing repeat it in a model-level body (modelBody).
  # allow_fallbacks: other endpoints of the same model only, never another model.
  routing = {
    require_parameters = true;
    quantizations = [ "fp4" "nvfp4" "fp8" ];
    allow_fallbacks = true;
    max_price = {
      prompt = 0.2;
      completion = 0.8;
    };
  };
  dataPolicy = {
    zdr = {
      data_collection = "deny";
      zdr = true;
    };
    public.data_collection = "allow";
  };

  # The rest comes from sandbox/opencode/opencode.json; the models
  # and the sandbox's Ollama bridge (inner) come from the llm options.
  # A model-level body replaces the provider-level one, so overridden models repeat the whole of it.
  modelBody = data: m: lib.optionalAttrs (m.routing != { }) {
    body.provider = routing // removeAttrs m.routing [ "zdr" "data_collection" "require_parameters" "allow_fallbacks" ] // dataPolicy.${data};
  };

  settings = data: lib.recursiveUpdate (lib.importJSON ./sandbox/opencode/opencode.json) {
    permissions = permissions.base ++ permissions.deny;
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
        (_: m: lib.nameValuePair (lib.removePrefix "openrouter/" m.id) ((modelBody data m) // {
          limit = {
            inherit (m) context;
            output = 16384;
          };
        }))
        cloudModels;
    };
  };

  # Per-repo config (OPENCODE_CONFIG), named after the profile in oc-sandbox; opencode appends
  # its permissions to the global ones, and the global denies are appended again after them.
  withDenies = p: p // { permissions = (p.permissions or [ ]) ++ permissions.deny; };
  repoProfiles = lib.mapAttrs (_: withDenies) {
    # Pilot clones stella-*: pilot rules before the repo's own instructions.
    stella-pilot.instructions = [
      "${mount}/pilot-rules.md"
      "/work/AGENTS.md"
      "/work/CLAUDE.md"
    ];
  };
  probe = withDenies { permissions = [{ action = "*"; resource = "*"; effect = "allow"; }]; };
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

  # Checks the permissions of both variants and of every profile on top (tests/oc-permissions.sh);
  # the probe profile allows everything and must still get every deny.
  repos = pkgs.runCommand "oc-sandbox-repos" { nativeBuildInputs = [ pkgs.bash pkgs.jq ]; } (
    lib.concatStrings (
      [ "mkdir $out\n" ]
      ++ lib.mapAttrsToList (n: v: "jq . ${json n v} > $out/${n}.json\n") repoProfiles
      ++ map (args: "bash ${./tests/oc-permissions.sh} ${./tests/oc-permissions.cases} ${args}\n") (
        [ (json "opencode" (settings "zdr")) (json "opencode-public" (settings "public")) ]
        ++ lib.mapAttrsToList (n: _: "${json "opencode" (settings "zdr")} $out/${n}.json") repoProfiles
      )
      ++ [
        "grep '^deny' ${./tests/oc-permissions.cases} > deny.cases\n"
        "bash ${./tests/oc-permissions.sh} deny.cases ${json "opencode" (settings "zdr")} ${json "probe" probe}\n"
      ]
    )
  );
}
