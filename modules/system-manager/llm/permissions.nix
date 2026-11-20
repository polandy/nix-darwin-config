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
    ++ each [ "read" "edit" "glob" "grep" "list" "lsp" "shell" "question" "todowrite" "subagent" "external_directory" ] "allow" [ "*" ];

  # Appended after every repo profile too, so no profile can lift them.
  deny =
    rules "read" "deny" [ "*.env" "*.env.*" ]
    ++ rules "read" "allow" [ "*.env.example" ]
    # The agent cannot change its own rules, git internals, CI or the owner's direnv.
    ++ rules "edit" "deny" [ "opencode.json" "opencode.jsonc" ".opencode/**" ".git/**" ".github/workflows/**" ".claude/**" ".envrc" ]
    # Key, prompt and repo config (/run/oc), process environments (/proc), the rest of $HOME.
    ++ rules "external_directory" "deny" [ "/run/*" "/proc/*" "/srv/*" "/root/*" "/home/*" ]
    ++ rules "external_directory" "allow" [ "/tmp/*" ]
    ++ each [ "webfetch" "websearch" "browser" "skill" "doom_loop" ] "deny" [ "*" ]
    ++ rules "shell" "deny" (
      [ "sudo *" "su" "su *" "doas *" "pkexec *" ]
      ++ [ "git push*" "git -C * push*" "git -c * push*" "*/git push*" "git remote*" "git -C * remote*" "git config*" "git -C * config*" ]
      ++ [ "curl *" "wget *" "nc *" "ncat *" "netcat *" "socat *" "ssh *" "scp *" "sftp *" "rsync *" "telnet *" "ftp *" ]
      # OPENROUTER_API_KEY is in the environment of every shell command.
      ++ [ "env" "env -0" "printenv*" "export -p" "declare -p*" "set" "*OPENROUTER*" "*/proc/*/environ*" "*/run/oc/*" ]
      ++ map (p: "rm -*r* ${p}") [ "/" "/work" "/work/" "." "./" ".git" ".git/" "~" "~/" ]
    )
    ++ rules "shell" "allow" [ "git config --get *" "git config -l" "git config --list" ];
}
