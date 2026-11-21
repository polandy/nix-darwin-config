#!/usr/bin/env bash
# Build-time test for sandbox/oc-config: which data policy each profile gets.
# Usage: oc-config.sh <oc-config> "<public repos>"
set -euo pipefail
oc_config=$1 public=$2
fail=0
# Via bash: the build sandbox has no /bin/bash for the shebang.
run() { bash "$oc_config" "$@"; }

# expect <profile> <zdr|public>
expect() {
  local got
  got=$(run "$1" openrouter/test-model | jq -c '.providers.openrouter.body.provider | {data_collection, zdr}')
  case $2 in
    zdr) want='{"data_collection":"deny","zdr":true}' ;;
    public) want='{"data_collection":"allow","zdr":null}' ;;
  esac
  if [[ $got != "$want" ]]; then
    echo "FAIL profile '$1': expected $2 ($want), got $got"
    fail=1
  fi
}

[[ -n $public ]] || { echo "FAIL no public repos to test"; exit 1; }
for r in $public; do
  expect "$r" public
done
# Fail closed: unknown, empty, partial or combined names get ZDR.
first=${public%% *}
expect "" zdr
expect unknown-repo zdr
expect "${first:0:3}" zdr
expect "${first}x" zdr
expect "$first $first" zdr
expect "*" zdr

# Shared settings in both variants.
for p in "$first" unknown-repo; do
  cfg=$(run "$p" openrouter/test-model)
  jq -e '.model == "openrouter/test-model"' <<<"$cfg" >/dev/null || { echo "FAIL $p: model not set"; fail=1; }
  jq -e '.provider.openrouter == null' <<<"$cfg" >/dev/null || { echo "FAIL $p: openrouter under legacy key"; fail=1; }
  jq -e '.providers.openrouter.body.provider.quantizations == ["fp4","nvfp4","fp8"]' <<<"$cfg" >/dev/null \
    || { echo "FAIL $p: quantizations"; fail=1; }
  jq -e '.providers.openrouter.body.provider.max_price == {prompt: 0.2, completion: 0.8}' <<<"$cfg" >/dev/null \
    || { echo "FAIL $p: max_price"; fail=1; }
  # A model-level body replaces the provider-level one, so it must carry the same data policy.
  jq -e --argjson d "$(jq -c '.providers.openrouter.body.provider | {data_collection, zdr}' <<<"$cfg")" \
    '[.providers.openrouter.models[] | select(has("body")) | .body.provider | select({data_collection, zdr} != $d)] | length == 0' \
    <<<"$cfg" >/dev/null || { echo "FAIL $p: model-level body drops the data policy"; fail=1; }
  jq -e '.providers.openrouter.models | .["openai/gpt-6.2-sol"].body.provider.max_price == {prompt: 2.5, completion: 10}
    and (.["moonshotai/kimi-k3.1-pro"].body.provider.max_price == {prompt: 1, completion: 4})
    and (.["z-ai/glm-5.3-flash"] | has("body") | not)' <<<"$cfg" >/dev/null \
    || { echo "FAIL $p: per-model routing"; fail=1; }
done

if run "$first" >/dev/null 2>&1; then
  echo "FAIL oc-config with one argument succeeded"
  fail=1
fi
exit $fail
