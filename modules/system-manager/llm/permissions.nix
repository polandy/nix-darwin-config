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
    # The agent cannot change its own rules, git internals, CI or the owner's direnv.
    ++ rules "edit" "deny" [ "opencode.json" "opencode.jsonc" ".opencode/**" ".git/**" ".github/workflows/**" ".claude/**" ".envrc" ]
    # Outside /work only these; never /run (key, prompt), /proc (environments) or $HOME.
    ++ rules "external_directory" "deny" [ "*" ]
    ++ rules "external_directory" "allow" [ "/tmp/*" "/usr/*" "/nix/store/*" "/etc/*" ]
    ++ each [ "webfetch" "websearch" "browser" "skill" "doom_loop" ] "deny" [ "*" ]
    ++ rules "shell" "deny" (
      [ "sudo *" "su" "su *" "doas *" "pkexec *" ]
      ++ [ "git push*" "git -C * push*" "git -c * push*" "git --* push*" "env git push*" "command git push*" "exec git push*" "*=* git push*" "*/git push*" "git remote*" "git -C * remote*" "git config*" "git -C * config*" ]
      ++ [ "curl *" "wget *" "nc *" "ncat *" "netcat *" "socat *" "ssh *" "scp *" "sftp *" "rsync *" "telnet *" "ftp *" ]
      # OPENROUTER_API_KEY is in the environment of every shell command.
      ++ [ "env" "env -0" "*/env" "printenv*" "export" "export -p" "declare -p*" "set" "compgen *" ]
      ++ [ "*OPENROUTER*" "*environ*" "*ENVIRON*" "*/run/oc*" ]
      ++ map (p: "rm -*r* ${p}") [ "?" ".." "./" "~/" "$HOME" "/work" "/work/*" "./*" ".git" ".git/*" "../*" ]
    );
}
