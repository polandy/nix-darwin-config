# The `llm` module (coolermaster)

`modules/system-manager/llm` runs local coding models on coolermaster and lets AI agents use them,
or a cloud model, without access to the owner's account, keys or network. It is a self-contained
system-manager module: `hosts/coolermaster/system.nix` imports it and turns it on with
`llm.enable`. Other hosts do not use it.

## Main parts

- **Ollama and its filter.** Ollama is the Arch service; the module only adds drop-ins and a LAN
  firewall. A small Caddy filter in front of it lets sandboxed agents use the chat API only, never
  the endpoints that pull, create or delete models.
- **Sandbox (`oc-sandbox`).** opencode runs as a separate user in a bubblewrap sandbox with its own
  network namespace. Its config is read-only from the Nix store, so the agent cannot change its
  own rules. Helper scripts (`oc`, `oc-net`, `oc-shot`, `oc-preview`, `oc-outbox`) cover herdr,
  temporary network grants, screenshots and handing results out as files.
- **Network guard.** The sandbox reaches the outside only through an egress proxy with an
  allowlist, enforced by nftables for the agent user. With a local model it gets no key and no
  egress at all, so private data stays on the host.
- **Model classes.** Models are defined once (`llm.models`); the policy groups four of them into
  classes: `cloud` (the default for workers), `cloud-fallback` (chosen only by the owner or the
  orchestrator when `cloud` is down or keeps failing; there is no automatic model fallback),
  `local` and `local-128k`. The module publishes them as
  a policy file that the orchestrator reads to pick a model. `local-nodraft` is not a policy class:
  it is the 64k Gemma without the base model's MTP draft model, because Ollama 0.40.11 does not plan
  the draft's memory and runs out of CUDA memory on the 16 GB card. `oc-sandbox --model` and the
  sandbox's `opencode.json` offer it like the other local models; the Stella pilot picks it per run
  (model argument of its `stella-task.sh`), while the `pilot-gemma4` job still uses `local`. The
  Ollama model `bench-gemma4-26b-nodraft` itself is created by hand on the host:

  ```sh
  ollama show --modelfile bench-gemma4-26b | grep -Ev '^DRAFT|draft_num_predict' > nodraft.Modelfile
  ollama create bench-gemma4-26b-nodraft -f nodraft.Modelfile
  ```

  Pilot stage b also offers `bench-gemma4-26b-128k-nodraft` (the same without the draft model, 128k)
  and `bench-qwen3-coder-next-128k` (Qwen3-Coder-Next 80B-A3B, 128k); both are Ollama models created
  by hand on the host and, like `local-nodraft`, no policy classes.

- **OpenRouter data policy.** The sandbox's `opencode.json` comes in two variants that differ
  only in OpenRouter's provider routing: ZDR endpoints with `data_collection: deny`, or, for the
  repos in `llm.sandbox.publicRepos` (public on GitHub), providers that may collect data.
  `oc-config` picks the variant per run by the repo's profile (throwaway clones count as their
  base repo: bench-* as skipper-cd, stella-* as Stella); anything not listed gets ZDR. The
  list is declared, not looked up, because the clones have no remote and the sandbox reaches
  GitHub only through the broker below; keep it in sync with the GitHub visibility. Both variants share quantizations
  (fp4, nvfp4, fp8), the price cap and the limits (output 16k). All routing sits in
  the provider-level `body`. Only models with `models.<name>.routing` (`gpt-sol` = openai/gpt-6.2-sol,
  `kimi-pro` = moonshotai/kimi-k3.1-pro) get a model-level `body`, which repeats the shared routing
  with their own quantizations and `max_price` (`require_parameters`, `allow_fallbacks` and the data keys cannot be overridden; `kimi-pro` also allows int4, Kimi's native format; `gpt-sol` costs about 12x the shared cap) plus the same data policy; `tests/oc-config.sh` checks that.
  Both are no policy classes, like `local-nodraft`; pick them with `--model`.
  `tests/oc-config.sh` checks the choice at build time. The OpenRouter block must use the v2 key
  `providers`: opencode 2.2.7 silently drops `body` under the legacy `provider` key.
- **Permissions (auto mode).** bwrap is the security boundary: user aiagent, only the clone as
  `/work` writable (plus `/tmp` and the per-repo opencode state), no network but the model's
  endpoint, no secrets but the read-only key. So opencode's rules (`permissions.nix`) allow normal
  work without prompts: read, edit and any shell command; outside `/work` only `/tmp`, `/usr`,
  `/nix/store` and `/etc`. Only unknown future actions still ask.
  - Denied, never asked, even if bwrap had a hole: git push/remote/config (with any global
    options), sudo/su, curl, wget, nc, ssh and friends, `rm -r` of `/work`, `.`, `.git` or `~`
    (a literal `*` cannot be matched, so `rm -rf *` is not denied), other paths outside `/work`,
    edit-tool writes to the agent's own config, `.git/`, CI workflows and `.envrc` (shell writes
    to them are not caught; PR review is the guard, and the owner must not run git on the host
    in a sandbox clone, whose `.git/hooks` the agent controls), web fetch/search,
    the v2 Code Mode tool `execute` (its runtime has `fetch`; the sandbox has no MCP servers, so
    nothing is lost), and `doom_loop` (an unattended run has nobody to answer the prompt, so a repeating call stops).
  - The key, best effort: `/run`, `/proc`, `env`, `printenv`, anything naming `OPENROUTER`,
    `os.environ`. inner exports the key into opencode's environment, which every
    shell command inherits, and `perl`, `awk` or `bash -c` can still print it; moving the key
    out of the environment is still open (the GitHub broker below keeps only its own token out). `*OPENROUTER*` also blocks grepping for the
    name; accepted. The `.env` deny covers the read tool only (`cat .env` is a shell command).
  - opencode 2.2.7 concatenates the rules of all config files and takes the last match, with `*`
    as a wildcard over the whole command text. The shell denies are pattern matches, not a parser:
    wrappers (`bash -c`, `timeout`, `xargs`) get past them, so they are defense in depth on top of
    bwrap. A `git -C` command with the word `push`, `remote` or `config` in its message is denied too.
  - `AGENTS.md`, `CLAUDE.md`, `flake.nix` and other repo files stay editable: they reach the
    owner's repo only through a reviewed PR; review `flake.nix` changes before `nix develop`.
  - Per-repo profiles (`OPENCODE_CONFIG`) may add rules, but the denies are appended again after
    them, so a profile can only narrow. A new repo works without a profile.
  - `tests/oc-permissions.sh` checks both variants and every profile against
    `tests/oc-permissions.cases` at build time, including a probe profile that allows everything.
    The test mirrors opencode's matcher; re-check it against the binary when opencode is upgraded.
- **GitHub broker (`oc-pr`).** The worker pushes its branch, opens its PR and merges it like the
  Claude workers, but the token never enters the sandbox (`pr-broker.nix`). Each fixed repo has a
  socket (`/run/oc-proxy/pr-<repo>.sock`, group aiagent) that `oc-sandbox` binds as
  `/run/oc/pr.sock` into that repo's sandbox only (not into throwaway clones or `--script`); per
  connection systemd starts `oc-pr-broker` as the dynamic user `oc-pr`, with the token from
  `llm.sandbox.github.tokenFile` as a credential. It knows three verbs, everything else is refused
  and logged to the journal (`journalctl -u 'oc-pr-*'`):
  - `oc-pr push [<branch>]`: only branches under `llm.sandbox.github.branchPrefixes` (`feat/`,
    `fix/`, ...; so never `main`, `gh-pages` or `release/*`), never the default branch,
    fast-forward only, no tags. The broker never runs git in the agent's clone (its `.git` config and hooks are the
    agent's): the client sends a git bundle of just that branch, the broker checks and fetches it
    (fsck) into its own mirror and pushes from there. The upload runs outside the per-repo lock
    with a deadline, every git or gh call has a timeout, and the mirror drops the incoming objects afterwards (`gc --prune=now`).
  - `oc-pr pr-create`: base is the default branch; title and body from the branch's commits unless
    given.
  - `oc-pr merge <pr>`: squash and delete the branch, only on a green gate with the semantics of
    herdr-orchestrator's `pr-gate.sh` (open, mergeable, all checks pass, the last "PR quality
    review" comment says ready and is newer than the head), stricter in three points: the comment
    must come from `llm.sandbox.github.reviewers`; the head time is the later of the commit date and
    the broker's own push of that commit (the agent sets the commit date); the merge is pinned to
    the checked head (`--match-head-commit`). The readiness line must say exactly "ready" or "not
    ready". Pending counts as refused; the agent asks again later. Any PR whose head is a feature
    branch qualifies, a human's too; the reviewer's comment is the consent.
  - What the broker does not guard: PR title and body are agent text posted under the owner's
    account, and CI runs the agent's code on every feature-branch push. The review gate on merge
    is the guard for what reaches the default branch.
  - Errors reach the sandbox as a short label ("gh pr create failed"); the detail goes to the
    journal with the token masked.
  - Raw `git push` stays denied in opencode (`permissions.nix`); `oc-pr` is an ordinary shell
    command. The token: fine-grained, only the repos in `llm.sandbox.repos`, Contents and Pull
    requests read/write (Metadata read is implied), no Workflows, so a push that changes
    `.github/workflows` is rejected by GitHub. The owner creates the file (root, 0600), see
    `docs/user/coolermaster-host-local-files.md`. Without the file the broker
    fails to start and `oc-pr` prints "no answer from the broker".
  - `tests/oc-pr-broker.py` runs client and broker at build time against a local bare repo and a
    fake `gh`: the refusals (protected branches in any case, bad names, unknown verbs, broken
    uploads, non-fast-forward, tags or another branch in the bundle, the red and pending gate
    reasons), a stalled upload that must not block a merge, and the green paths.
- **Jobs, GPU lock, slices.** Long runs (pilot, bench) are systemd jobs that take a shared GPU
  lock, so only one local model run uses the GPU at a time; a run that cannot get it is
  deferred. Slices give LLM work priority over e2e containers.

## Where the details live

| Topic | Place |
|---|---|
| Options and shared values | `modules/system-manager/llm/default.nix` |
| One part per file (Ollama, filter, firewall, sandbox, jobs, policy) | the other `.nix` files in the module and their comments |
| Sandbox usage | header comment of `sandbox/oc-sandbox` |
| How it fits system-manager, what a switch changes, checks | PR #8 description |
| Host-local files (agent user, key, sudoers, LAN files) | [`docs/user/coolermaster-host-local-files.md`](../user/coolermaster-host-local-files.md) |

Threat model and sandbox decisions live with the sandbox plan in the `ai-sandbox` repo;
bench results in `coding-model-bench`.
