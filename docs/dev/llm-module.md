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

- **OpenRouter data policy.** The sandbox's `opencode.json` comes in two variants that differ
  only in OpenRouter's provider routing: ZDR endpoints with `data_collection: deny`, or, for the
  repos in `llm.sandbox.publicRepos` (public on GitHub), providers that may collect data.
  `oc-config` picks the variant per run by the repo's profile (throwaway clones count as their
  base repo: bench-* as skipper-cd, stella-* as Stella); anything not listed gets ZDR. The
  list is declared, not looked up, because the clones have no remote and the sandbox has no
  GitHub access; keep it in sync with the GitHub visibility. Both variants share quantizations
  (fp4, nvfp4, fp8), the price cap and the limits (context 200k, output 16k). All routing sits in
  the provider-level `body`, so no model-level `body` can shadow the data policy.
  `tests/oc-config.sh` checks the choice at build time. The OpenRouter block must use the v2 key
  `providers`: opencode 2.2.7 silently drops `body` under the legacy `provider` key.
- **Permissions (auto mode).** bwrap is the security boundary: user aiagent, only the clone as
  `/work` writable (plus `/tmp` and the per-repo opencode state), no network but the model's
  endpoint, no secrets but the read-only key. So opencode's rules (`permissions.nix`) allow normal
  work without prompts: read, edit and any shell command; outside `/work` only `/tmp`, `/usr`,
  `/nix/store` and `/etc`. Only unknown future actions still ask. Denied, never asked: things that
  must not happen even if bwrap had a hole (git push/remote/config, sudo/su, curl, wget,
  nc, ssh and friends, `rm -r` of `/work`, `.`, `.git` or `~`; a literal `*` cannot be matched), the common ways to read the key (`/run`, `/proc`, `env`, `printenv`, anything naming `OPENROUTER`,
  `os.environ` or `process.env`; best effort only: inner exports the key into opencode's environment,
  which every shell command inherits, and `perl`/`awk`/`bash -c` can still print it; #17 moves the key out of the environment), `.env` files (read tool only; `cat .env` is a shell command), other paths outside `/work`,
  edits of the agent's own config, `.git/`, CI workflows and `.envrc`, and web fetch/search. opencode
  2.2.7 concatenates the rules of all config files and takes the last match, with `*` as a
  wildcard over the whole command text, so the shell denies are pattern matches, not a parser:
  defense in depth on top of bwrap. `AGENTS.md`/`CLAUDE.md` stay editable: they are repo
  content and reach the owner's repo only through a reviewed PR. Per-repo profiles (`OPENCODE_CONFIG`) may add rules, but the
  denies are appended again after them, so a profile can only narrow. A new repo works without
  a profile. `tests/oc-permissions.sh` checks both variants and every profile against
  `tests/oc-permissions.cases` at build time, including a probe profile that allows everything. The test mirrors opencode's matcher;
  re-check it against the binary when opencode is upgraded.
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
