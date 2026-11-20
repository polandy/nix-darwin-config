{ config, lib, pkgs, ... }:

let
  cfg = config.llm;
  gh = cfg.sandbox.github;
  inherit (import ./sockets.nix { inherit cfg pkgs; }) sandboxSocket;
  # GitHub broker for the sandbox (push, pr-create, merge), one socket per fixed repo, so a
  # sandbox reaches only its own repo. Design and owner setup: docs/dev/llm-module.md.
  script = name: checkPhase: pkgs.writeTextFile {
    inherit name checkPhase;
    executable = true;
    destination = "/bin/${name}";
    text = builtins.readFile ./sandbox/${name};
  };
  broker = script "oc-pr-broker" ''
    ${pkgs.python3}/bin/python3 -I -c 'import ast, sys; ast.parse(open(sys.argv[1]).read())' "$target"
  '';
  # Runs in the sandbox (host python and git); tests/oc-pr-broker.py drives it against the broker.
  client = script "oc-pr" ''
    PATH=${lib.makeBinPath [ pkgs.git pkgs.coreutils ]}:$PATH ${pkgs.python3}/bin/python3 ${./tests/oc-pr-broker.py} ${broker}/bin/oc-pr-broker "$target"
  '';
  unit = repo: "oc-pr-${repo}";
in
{
  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [ "L+ ${cfg.binDir}/oc-pr - - - - ${client}/bin/oc-pr" ];

    systemd.sockets = lib.listToAttrs (map
      (repo: lib.nameValuePair (unit repo) (sandboxSocket "${cfg.socketDir}/pr-${repo}.sock" 2 // {
        description = "GitHub broker socket for the opencode sandbox of ${repo}";
      }))
      cfg.sandbox.repos);

    systemd.services = lib.listToAttrs (map
      (repo: lib.nameValuePair "${unit repo}@" {
        description = "GitHub broker for the opencode sandbox (${gh.owner}/${repo})";
        path = [ pkgs.git pkgs.gh ];
        environment = {
          OC_PR_REVIEWERS = lib.concatStringsSep " " gh.reviewers;
          SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
          GIT_SSL_CAINFO = "/etc/ssl/certs/ca-certificates.crt";
        };
        serviceConfig = {
          ExecStart = "${pkgs.python3}/bin/python3 -I ${broker}/bin/oc-pr-broker ${gh.owner}/${repo}";
          StandardInput = "socket";
          StandardOutput = "socket";
          StandardError = "journal";
          # Shared name: all repos' instances use one uid, so the state directory keeps its owner.
          User = "oc-pr";
          DynamicUser = true;
          StateDirectory = "oc-pr";
          StateDirectoryMode = "0700";
          LoadCredential = "github-token:${gh.tokenFile}";
          RuntimeMaxSec = 900;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          CapabilityBoundingSet = "";
          RestrictAddressFamilies = "AF_INET AF_INET6 AF_UNIX";
        };
      })
      cfg.sandbox.repos);
  };
}
