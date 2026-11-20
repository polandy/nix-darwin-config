{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  opencode = import ./opencode.nix { inherit cfg lib pkgs; };

  # The scripts in sandbox/ are the reviewed ai-sandbox versions; only paths,
  # ports, models and repos are @placeholders@ filled from the llm options. They
  # keep their host interpreters and call host tools (bwrap, opencode, socat,
  # chromium from Arch) by name, inside and outside the sandbox, as before.
  vars = {
    inherit (cfg) agentUser agentHome agentDir ownerUser binDir socketDir sandboxNetDir;
    inherit (cfg.sandbox) keyFile;
    proxyPort = toString cfg.ports.proxy;
    ollamaPort = toString cfg.ports.ollama;
    defaultModel = cfg.models.cloud.id;
    modelCase = lib.concatMapStringsSep "|" (m: m.id) (lib.attrValues cfg.models);
    repoCase = lib.concatStringsSep "|" cfg.sandbox.repos;
    repos = lib.concatStringsSep " " cfg.sandbox.repos;
    opencode = "${opencode.config}";
    opencodeMount = opencode.mount;
    opencodePublic = "${opencode.public}";
    publicRepos = lib.concatStringsSep " " cfg.sandbox.publicRepos;
    ocConfig = "${oc-config}/bin/oc-config";
    repoProfiles = "${opencode.repos}";
    inner = "${inner}/bin/inner";
    herdrFilter = "${herdr-filter}/bin/herdr-filter";
  };
  fill = text: builtins.replaceStrings (map (n: "@${n}@") (lib.attrNames vars)) (lib.attrValues vars) text;

  tool = name: checkPhase: pkgs.writeTextFile {
    inherit name checkPhase;
    executable = true;
    destination = "/bin/${name}";
    text = fill (builtins.readFile ./sandbox/${name});
  };
  shellCheck = name: ''
    if grep -n '@[A-Za-z]*@' "$target"; then echo "unfilled placeholder in ${name}"; exit 1; fi
    ${pkgs.shellcheck}/bin/shellcheck --rcfile ${./sandbox/.shellcheckrc} -S warning "$target"
  '';
  shell = name: tool name (shellCheck name);

  inner = shell "inner";
  oc-config = tool "oc-config" ''
    ${shellCheck "oc-config"}
    PATH=${pkgs.jq}/bin:$PATH ${pkgs.bash}/bin/bash ${./tests/oc-config.sh} "$target" ${lib.escapeShellArg vars.publicRepos}
  '';
  herdr-filter = tool "herdr-filter" ''
    ${pkgs.python3}/bin/python3 -I -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$target"
  '';
  oc-shot = tool "oc-shot" ''
    ${pkgs.nodejs}/bin/node --check "$target"
  '';

  # Called by name, so linked into binDir. oc-sandbox and oc-net are named in
  # sudoers (host-local /etc/sudoers.d), oc-shot and oc-preview run in the sandbox.
  linked = {
    oc-sandbox = shell "oc-sandbox";
    oc = shell "oc";
    oc-net = shell "oc-net";
    oc-preview = shell "oc-preview";
    oc-outbox = shell "oc-outbox";
    inherit oc-shot;
  };
in
{
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = lib.mapAttrsToList (n: p: "L+ ${cfg.binDir}/${n} - - - - ${p}/bin/${n}") linked;
  };
}
