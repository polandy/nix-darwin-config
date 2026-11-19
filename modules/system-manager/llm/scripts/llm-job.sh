# llm-job <name>: runs the job from @jobsDir@/<name>.env (as @agentUser@, from llm-job@<name>).
# Job kinds (JOB=):
#   bench   Bench series in @agentDir@/coding-model-bench, SANDBOX=1 (opencode and scoring
#           in oc-sandbox). SERIES="<name> <ollama-model> <ctx> <task>:<reps> ...", optional
#           TIMEOUT, EMPTY_RETRIES, PROMPT_SUFFIX.
#   pilot   Stella pilot in path A (pilot/pilot.sh in the ai-sandbox clone PILOT_DIR, default
#           @agentDir@/ai-sandbox), MODEL (default @pilotModel@), optional PILOT_TIMEOUT.
# run.sh and stella-task.sh take the GPU lock per run (llm-gpu, 90 min, else exit 75 = deferred).
# OLLAMA_KEEP_ALIVE=0 unloads the models after the job (ExecStopPost llm-job-unload, as root);
# without it the Ollama default applies.

die() { echo "llm-job: $*" >&2; exit 2; }
[[ $(id -un) == @agentUser@ ]] || die "must run as @agentUser@"
name=${1:-}
[[ $name =~ ^[a-z0-9-]{1,48}$ ]] || die "invalid job name: $name"
: "${JOB:?JOB missing in @jobsDir@/$name.env}"

case $JOB in
  bench)
    : "${SERIES:?SERIES missing}"
    bench=${BENCH_DIR:-@agentDir@/coding-model-bench}
    [[ -x $bench/bench/series.sh ]] || die "no bench clone: $bench"
    read -ra series <<< "$SERIES"
    export SANDBOX=1
    exec "$bench/bench/series.sh" "${series[@]}" ;;
  pilot)
    pilot=${PILOT_DIR:-@agentDir@/ai-sandbox}/pilot/pilot.sh
    [[ -x $pilot ]] || die "no ai-sandbox clone: $pilot"
    exec "$pilot" "${MODEL:-@pilotModel@}" ;;
  *) die "unknown job kind: $JOB" ;;
esac
