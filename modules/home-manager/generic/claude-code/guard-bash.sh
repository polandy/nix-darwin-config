# PreToolUse hook for Bash: blocks dangerous commands even when they are hidden
# in pipes, subshells, `bash -c` or after `;`/`&&`. The permission rules in
# settings.json only match the start of a command, so `ls; sudo x` or
# `echo $(curl ...)` slip past them. Exit code 2 blocks the call and hands
# stderr back to Claude.
#
# This is defense in depth, not a sandbox: a determined model can still
# obfuscate (base64, variables, written scripts). The real boundaries are
# Claude Code's sandbox and what the user account may touch.

cmd=$(jq -r '.tool_input.command // empty')
[ -z "$cmd" ] && exit 0

# Start of a command: line start, after ; & | ( ` $( { or find's -exec/-ok,
# plus optional VAR=value assignments and wrappers like env/xargs, plus an
# optional quote, backslash or directory in front of the name ("sudo",
# \sudo, /usr/bin/sudo).
sep='(^|[;&|({`]|\$\(|-(exec|ok)(dir)?[[:space:]])'
prefix='[[:space:]]*(([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*|env|command|exec|nohup|time|xargs|nice)([[:space:]]+-[^[:space:]]+)*[[:space:]]+)*(["'\''\\]|/[^[:space:]]*/)?'
start="${sep}${prefix}"
# End of a command name, allowing a closing quote.
end='["'\'']?([[:space:]]|$|[;&|)])'

block() {
  echo "Blocked by guard-bash hook: $1. Ask the user to run it themselves." >&2
  exit 2
}

check() {
  if printf '%s\n' "$cmd" | grep -Eq -- "$2"; then block "$1"; fi
}

check "privilege escalation" "${start}(sudo|su|doas)${end}"
check "system configuration" "${start}(sysctl|launchctl|pmset|diskutil|nvram|csrutil|systemsetup|defaults|chmod|chown|chflags)${end}"
check "network access" "${start}(curl|wget|nc|ncat|socat|ssh|scp|sftp)${end}"
check "nested shell" "${start}eval${end}|${start}(ba|z|fi|da)?sh[[:space:]]+-[a-z]*c"
check "inline script" "${start}(python[0-9.]*|perl|ruby|node|osascript)[[:space:]]+(-[a-zA-Z]*[ce]|--command|--eval)"
check "piping into a shell" "\|${prefix}(ba|z|fi|da)?sh${end}"
# Interpreters only when they read the script from stdin: `| python3 -m json.tool` is fine.
check "piping into an interpreter" "\|${prefix}(python[0-9.]*|perl|ruby|node|osascript)[\"']?[[:space:]]*(-[[:space:]]*)?($|[;&|)])"

# rm with both a recursive and a force flag, in any spelling or order.
rm_args=$(printf '%s\n' "$cmd" | grep -Eo -- "${start}rm[[:space:]][^;&|)]*" || true)
if printf '%s\n' "$rm_args" | grep -Eq -- '[[:space:]](-[a-zA-Z]*[rR]|--recursive)' &&
  printf '%s\n' "$rm_args" | grep -Eq -- '[[:space:]](-[a-zA-Z]*f|--force)'; then
  block "recursive forced delete"
fi
check "history rewrite" "git[[:space:]]+(push[^;&|]*[[:space:]](--force|-f([[:space:]]|$)|\+)|reset[[:space:]]+--hard|clean[[:space:]]+-[a-z]*f)"
check "secret access" "(\.ssh/|\.aws/|\.gnupg/|\.config/sops/|(^|[[:space:]/\"'=])\.env([[:space:]]|$|\.|[\"'])|\.pem([[:space:]]|$|[\"'])|id_(rsa|ecdsa|ed25519|dsa)([[:space:]]|$|[\"']))"

exit 0
