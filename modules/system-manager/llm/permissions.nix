# opencode permission rules for the sandbox (imported by opencode.nix); model in docs/dev/llm-module.md.
# opencode 2.2.7 takes the last matching rule; `*` matches anything, a trailing ` *` also nothing.
{ lib }:

let
  rules = action: effect: map (resource: { inherit action resource effect; });
  each = actions: effect: resources: lib.concatMap (a: rules a effect resources) actions;
in
rec {
  # Normal work runs without prompts; only unknown (future) actions still ask.
  base = [{ action = "*"; resource = "*"; effect = "ask"; }]
    ++ each [ "read" "edit" "glob" "grep" "list" "lsp" "shell" "question" "todowrite" "subagent" ] "allow" [ "*" ];

  # Appended after every repo profile too, so no profile can lift them.
  deny =
    rules "read" "deny" [ "*.env" "*.env.*" ]
    ++ rules "read" "allow" [ "*.env.example" ]
    # Edit tool only; shell writes reach these too and are caught in PR review.
    ++ rules "edit" "deny" (lib.concatMap (f: [ f "*/${f}" ]) [ "opencode.json" "opencode.jsonc" ".opencode/**" ".git/**" ".github/workflows/**" ".claude/**" ".envrc" ])
    # Outside /work only these; never /run (key, prompt), /proc (environments) or $HOME.
    ++ rules "external_directory" "deny" [ "*" ]
    ++ rules "external_directory" "allow" [ "/tmp/*" "/usr/*" "/nix/store/*" "/etc/*" ]
    ++ each [ "webfetch" "websearch" "browser" "skill" "doom_loop" ] "deny" [ "*" ]
    ++ rules "shell" "deny" (
      [ "sudo *" "su" "su *" "doas *" "pkexec *" ]
      # Any global options before the subcommand (`-C`, `-c`, `-p`, `--no-pager`, ...), plus prefixed forms.
      ++ lib.concatMap (sub: lib.concatMap (g: [ g "*/${g}" "env ${g}" "command ${g}" "exec ${g}" ]) [ "git ${sub} *" "git -* ${sub} *" ]) [ "push" "remote" "config" ]
      ++ lib.concatMap (t: [ "${t} *" "*/${t} *" "env ${t} *" "command ${t} *" "exec ${t} *" ]) [ "curl" "wget" "nc" "ncat" "netcat" "socat" "ssh" "scp" "sftp" "rsync" "telnet" "ftp" ]
      # OPENROUTER_API_KEY is in the environment of every shell command.
      ++ [ "env" "env -0" "*/bin/env" "printenv*" "export" "export -p" "declare -p*" "declare -x*" "typeset *" "set" "compgen *" ]
      ++ [ "*OPENROUTER*" "*os.environ*" "* /proc/*" "*</proc/*" "*/run/oc*" ]
      ++ map (p: "rm -*r* ${p}") [ "/" "." ".." "./" "~" "~/" "$HOME" "/work" "/work/*" ".git" ".git/*" "./.git" "./.git/*" "-- ." "-- /work" "../*" ]
    );
}
