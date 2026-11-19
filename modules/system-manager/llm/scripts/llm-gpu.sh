# llm-gpu run <tag> <cmd> [args...]   Run cmd while holding the GPU lock.
# llm-gpu status                      Print "free" (exit 0) or "busy <holder>" (exit 1).
#
# One local GPU user at a time (bench, pilot, local workers): @gpuLock@, group @group@.
# run waits up to LLM_GPU_WAIT seconds (default 5400 = 90 min, owner decision 4.1). On timeout
# it logs "deferred" (journal tag llm-gpu, and to LLM_GPU_LOG if set) and exits 75 (EX_TEMPFAIL);
# no fallback to the cloud, the owner decides (7.1 b). The holder's tag is in the lock file.
# The orchestrator calls "status" before it starts a worker and picks the cloud when busy.
lock=${LLM_GPU_LOCK:-@gpuLock@}
usage() {
  echo "usage: llm-gpu run <tag> <cmd> [args...] | llm-gpu status" >&2
  exit 2
}
log() {
  logger -t llm-gpu -- "$*" 2>/dev/null || true
  [ -n "${LLM_GPU_LOG:-}" ] && echo "$(date -Is) $*" >> "$LLM_GPU_LOG"
  echo "llm-gpu: $*" >&2
}
case ${1:-} in
  status)
    exec 9<"$lock" || { echo "no lock file $lock" >&2; exit 2; }
    if flock -n -s 9; then echo free; exit 0; fi
    echo "busy $(head -c 200 "$lock")"; exit 1 ;;
  run)
    [ $# -ge 3 ] || usage
    tag=$2; shift 2
    # Open without truncating: the holder's tag must survive a waiting caller.
    exec 9<>"$lock" || { log "cannot open $lock (member of group @group@? log in again after joining)"; exit 2; }
    if ! flock -w "${LLM_GPU_WAIT:-5400}" 9; then
      log "deferred $tag: GPU busy for ${LLM_GPU_WAIT:-5400}s ($(head -c 200 "$lock"))"
      exit 75
    fi
    printf '%s pid=%s since=%s\n' "$tag" "$$" "$(date -Is)" > "$lock"
    "$@"; rc=$?
    : > "$lock"
    exit "$rc" ;;
  *) usage ;;
esac
