# llm-job-unload <name>: ExecStopPost of llm-job@<name> (as root). Unloads every loaded
# Ollama model when @jobsDir@/<name>.env sets OLLAMA_KEEP_ALIVE=0. The agent user only
# reaches the chat API (ollama-filter), hence this step outside the job.
name=${1:-}
[[ $name =~ ^[a-z0-9-]{1,48}$ ]] || exit 0
env=@jobsDir@/$name.env
ka=$(sed -n 's/^OLLAMA_KEEP_ALIVE=["'\'']\{0,1\}\([^"'\'']*\).*/\1/p' "$env" 2>/dev/null | tail -1)
[[ $ka == 0 ]] || exit 0
api=http://@ollama@
for m in $(curl -sf -m 5 "$api/api/ps" | jq -r '.models[].name'); do
  curl -sf -m 30 "$api/api/generate" -d "$(jq -cn --arg m "$m" '{model:$m,keep_alive:0}')" > /dev/null \
    && logger -t llm-job -- "$name: $m unloaded"
done
exit 0
