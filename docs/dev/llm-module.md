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
- **Model classes.** Models are defined once and grouped into classes: `cloud` (the default for
  workers), `local` and `local-128k`. The module publishes them as a policy file that the
  orchestrator reads to pick a model. `local-nodraft` is not a policy class: it is the 64k Gemma
  without the base model's MTP draft model, because Ollama 0.40.11 does not plan the draft's memory
  and runs out of CUDA memory on the 16 GB card. `oc-sandbox --model` and the sandbox's
  `opencode.json` offer it like the other local models; the Stella pilot picks it per run (model
  argument of its `stella-task.sh`), while the `pilot-gemma4` job still uses `local`. The Ollama model
  `bench-gemma4-26b-nodraft` itself is created by hand on the host (`ollama show --modelfile
  bench-gemma4-26b` minus the `DRAFT` and `draft_num_predict` lines).
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
