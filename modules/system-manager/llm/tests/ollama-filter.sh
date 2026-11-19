#!/usr/bin/env bash
# Build-time test for the ollama-filter Caddyfile (filter.nix): runs it against
# a stub upstream on the Ollama port and checks what passes. Needs the Nix
# build sandbox (own loopback), because it binds the real filter and Ollama ports.
# Usage: ollama-filter.sh <Caddyfile> <filter host:port> <ollama host:port>
set -euo pipefail
caddyfile=$1 filter=$2 ollama=$3
export HOME=$PWD XDG_DATA_HOME=$PWD XDG_CONFIG_HOME=$PWD

printf '{\n\tadmin off\n\tauto_https off\n}\nhttp://:%s {\n\tbind %s\n\trespond "upstream"\n}\n' \
  "${ollama##*:}" "${ollama%:*}" >upstream.Caddyfile
caddy run --adapter caddyfile --config upstream.Caddyfile >upstream.log 2>&1 &
caddy run --adapter caddyfile --config "$caddyfile" >filter.log 2>&1 &
trap 'kill $(jobs -p) 2>/dev/null || true' EXIT

for _ in $(seq 50); do
  curl -s -o /dev/null "http://$ollama/" && curl -s -o /dev/null "http://$filter/" && break
  sleep 0.1
done

fail=0
# expect <status> <body> <method> <path> <Host header>
expect() {
  local got
  got=$(curl -s --path-as-is -X "$3" -H "Host: $5" -w ' %{http_code}' "http://$filter$4")
  if [ "$got" != "$2 $1" ]; then
    echo "FAIL $3 $4 Host=$5: expected '$2 $1', got '$got'"
    fail=1
  fi
}

# The sandbox reaches the filter through a socket bridge, so the Host header is
# whatever the client sends: opencode sends 127.0.0.1:<ollama port>, curl
# --unix-socket sends localhost. The filter must not depend on it.
for host in "$filter" "$ollama" localhost example.org; do
  expect 200 upstream GET /v1/models "$host"
  expect 200 upstream POST /v1/chat/completions "$host"
  expect 403 "" GET /api/tags "$host"
  expect 403 "" DELETE /api/delete "$host"
  expect 403 "" POST /api/pull "$host"
  expect 403 "" POST /api/create "$host"
  expect 403 "" POST /api/generate "$host"
  expect 403 "" GET / "$host"
  expect 403 "" POST /v1/models "$host"
  expect 403 "" GET /v1/chat/completions "$host"
  expect 403 "" DELETE /v1/chat/completions/../../api/delete "$host"
done

if [ "$fail" != 0 ]; then
  echo "--- filter.log"
  cat filter.log
  exit 1
fi
echo "ollama-filter: all checks passed"
