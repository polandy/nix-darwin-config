# Health check for the AI server: run `ai-server-check` on amst after setup or
# after a change. Expected values come from my.aiServer via runtimeEnv.
# Exits non-zero if any check fails.

failed=0
pass() { printf '  \033[32mok\033[0m    %s\n' "$1"; }
fail() {
  printf '  \033[31mFAIL\033[0m  %s\n' "$1"
  [ -n "${2:-}" ] && printf '        -> %s\n' "$2"
  failed=1
}

echo "System"
if /usr/bin/fdesetup isactive >/dev/null 2>&1; then
  fail "FileVault is on" "an unattended reboot stops at the unlock screen; run: sudo fdesetup disable"
else
  pass "FileVault is off"
fi

limit=$(/usr/sbin/sysctl -n iogpu.wired_limit_mb 2>/dev/null || echo "?")
if [ "$limit" = "$GPU_WIRED_LIMIT_MB" ]; then
  pass "iogpu.wired_limit_mb = $limit"
else
  fail "iogpu.wired_limit_mb = $limit, expected $GPU_WIRED_LIMIT_MB" "sudo launchctl kickstart system/org.nixos.gpu-wired-limit"
fi

pm=$(/usr/bin/pmset -g)
if printf '%s\n' "$pm" | grep -Eq '^[[:space:]]*sleep[[:space:]]+0' &&
  printf '%s\n' "$pm" | grep -Eq '^[[:space:]]*autorestart[[:space:]]+1'; then
  pass "never sleeps, restarts after power failure"
else
  fail "pmset: sleep/autorestart not as configured" "re-run darwin-rebuild switch; check pmset -g"
fi

echo "Services"
for svc in mlx-server litellm; do
  if /bin/launchctl print "system/org.nixos.$svc" 2>/dev/null | grep -q 'state = running'; then
    pass "$svc is running"
  else
    fail "$svc is not running" "tail ~/Library/Logs/$svc.log"
  fi
done

if curl -sf --max-time 5 "http://127.0.0.1:$MLX_PORT/v1/models" >/dev/null; then
  pass "mlx_lm.server answers on :$MLX_PORT"
else
  fail "mlx_lm.server does not answer on :$MLX_PORT" \
    "on first start it downloads $MODEL; watch ~/Library/Logs/mlx-server.log and du -sh ~/.cache/huggingface"
fi

# End to end: an Anthropic Messages API request through LiteLLM to the model,
# the same path Claude Code takes.
reply=$(curl -sf --max-time 300 "http://127.0.0.1:$PROXY_PORT/v1/messages" \
  -H 'content-type: application/json' \
  -H 'x-api-key: dummy' \
  -H 'anthropic-version: 2023-06-01' \
  -d '{"model":"claude-check","max_tokens":16,"messages":[{"role":"user","content":"Reply with OK."}]}' |
  jq -r '.content[0].text // empty' 2>/dev/null || true)
if [ -n "$reply" ]; then
  pass "Anthropic API via LiteLLM on :$PROXY_PORT answers: $(printf '%s' "$reply" | head -c 40)"
else
  fail "no answer from LiteLLM /v1/messages on :$PROXY_PORT" "tail ~/Library/Logs/litellm.log"
fi

echo "Network"
if tailscale status >/dev/null 2>&1; then
  pass "Tailscale is connected"
  if tailscale serve status 2>/dev/null | grep -q "127.0.0.1:$PROXY_PORT"; then
    pass "tailscale serve exposes the proxy: $(tailscale serve status 2>/dev/null | grep -Eo 'https://[^ ]+' | head -1)"
  else
    fail "tailscale serve does not expose :$PROXY_PORT" "sudo tailscale serve --bg $PROXY_PORT"
  fi
else
  fail "Tailscale is not logged in" "sudo tailscale up"
fi

if [ "$failed" -eq 0 ]; then
  echo "All checks passed."
else
  echo "Some checks failed."
fi
exit "$failed"
