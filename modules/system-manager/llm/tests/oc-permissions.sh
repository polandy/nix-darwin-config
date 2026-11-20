#!/usr/bin/env bash
# Build-time test for the sandbox's opencode permissions: the effect each case gets.
# Usage: oc-permissions.sh <cases> <opencode.json> [<repo.json>]
# Mirrors opencode 2.2.7: rules of all config files in load order, the last match wins
# (none: ask); `*` matches anything, `?` one character, a trailing ` *` also nothing.
set -euo pipefail
cases=$1; shift
rules=$(jq -s '[.[].permissions // [] | .[]]' "$@")
fail=0 n=0

effect() {
  jq -r --arg a "$1" --arg r "$2" '
    def glob: gsub("(?<c>[.+^${}()|\\[\\]\\\\])"; "\\\(.c)") | gsub("\\*"; ".*") | gsub("\\?"; ".")
      | if endswith(" .*") then .[:-3] + "( .*)?" else . end | "^" + . + "$";
    def matches($s; $p): $s | test($p | glob; "s");
    [.[] | select(matches($a; .action) and matches($r; .resource))] | last.effect // "ask"
  ' <<<"$rules"
}

while IFS=$'\t' read -r want action resource; do
  [[ -z $want || $want == \#* ]] && continue
  got=$(effect "$action" "$resource")
  n=$((n + 1))
  if [[ $got != "$want" ]]; then
    echo "FAIL $* : $action '$resource': expected $want, got $got"
    fail=1
  fi
done <"$cases"
(( n > 0 )) || { echo "FAIL no cases in $cases"; exit 1; }
exit $fail
