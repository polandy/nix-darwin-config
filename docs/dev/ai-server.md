# AI server (Mac Studio, host `amst`)

Status: **analysis only**. This describes how such a setup would look. Everything evaluates, but none of it has run on real hardware.

A Mac Studio with 256 GB unified memory, run headless 24/7 as a local LLM inference server for Claude Code on the dev machines.

## Architecture

```
dev machine                         amst (headless, nix-darwin)
-----------                         ------------------------------------------------
claude ──ANTHROPIC_BASE_URL──▶ tailscale serve :443 ──▶ LiteLLM :4000 (Anthropic API)
                                                          │  "*" → openai/<model>
                                                          ▼
                                                   mlx_lm.server :8080 (OpenAI API)
                                                          │  Metal, unified memory
                                                          ▼
                                                   ~/.cache/huggingface
```

- **Claude Code speaks the Anthropic Messages API, `mlx_lm.server` speaks the OpenAI API.** Pointing Claude Code straight at MLX does not work. LiteLLM translates between them.
- Both servers listen on loopback only, and neither has authentication. They are reachable only through Tailscale.

## What is where

| File | Contents |
|------|----------|
| `hosts/amst/default.nix` | Host: hostname, memory split, default model |
| `hosts/amst/bootstrap.sh` | Idempotent first-time setup on a fresh Mac |
| `modules/macos/ai-server/default.nix` | `my.aiServer` options: power, SSH, Tailscale, GPU limit, launchd daemons |
| `modules/macos/ai-server/check.sh` | `ai-server-check`: health check from FileVault to an end-to-end API request |
| `modules/home-manager/generic/claude-code/` | Hardened Claude Code settings + PreToolUse hook (imported on `amst` only) |
| `modules/home-manager/generic/ai-client.nix` | `claude-local` fish function for dev machines (`my.aiClient.url`) |

The step-by-step setup is in [docs/user/ai-server-setup.md](../user/ai-server-setup.md).

## Memory split (256 GB)

| Part | Size |
|------|------|
| macOS + services | ~28 GB (`gpuWiredLimitMb = 233472` → 228 GB for the GPU) |
| Model weights | up to ~180 GB |
| KV cache | the rest; grows with context length |

The default model, `mlx-community/Qwen3-235B-A22B-4bit` (~130 GB), is a placeholder. Check the size of each candidate on Hugging Face and leave room for the KV cache.

## Design decisions

- **MLX comes from PyPI via `uvx`, not nixpkgs.** nixpkgs builds `mlx` with `MLX_BUILD_METAL=false`, because the Metal compiler isn't open source, so it would run on the CPU only. The PyPI wheels include Metal. The version is pinned with `my.aiServer.mlx.version`.
- **LiteLLM comes from nixpkgs.** It is pure Python and needs no Metal.
- **Services are launchd daemons with `UserName`, not user agents.** User agents only start after a GUI login, which never happens on a headless machine.
- **Tailscale runs as nix-darwin's `services.tailscale` (root daemon), not the GUI app.** The GUI app also needs a logged-in user.
- **Power settings use nix-darwin options** (`power.sleep.*`, `power.restartAfterPowerFailure`, `networking.wakeOnLan`) instead of raw `pmset`.
- **There is no `switch-model.sh`.** Rewriting the launchd plist imperatively fights nix-darwin, which overwrites it on the next switch. Two ways to switch models:
  - Permanently: change `my.aiServer.model`, then `just switch`.
  - Ad hoc: `mlx_lm.server` loads the model named in a request's `model` field. To be verified on the machine: whether this also works through LiteLLM's `"*"` route.

## Caveats

- **FileVault stays off.** With FileVault on, a Mac that reboots after a power cut stops at the pre-boot unlock screen, and services and SSH stay down until someone types the password at the machine. Unattended recovery wins for this machine. nix-darwin cannot manage FileVault, so make sure it's off during macOS setup (`fdesetup status`). The consequence is that the disk is unencrypted at rest. Keep no long-lived secrets on `amst` beyond what it needs: no personal SSH keys that unlock other machines, no cloud credentials. Use a Hugging Face token only if gated models require one.
- `amst` imports only `modules/macos` (base) and `ai-server`, not `modules/macos/desktop`: no GUI casks, UI defaults, fonts or App Store apps.
- `uvx` downloads mlx-lm from PyPI on the first start. The model downloads from Hugging Face on the first start or request, which can take a long time for 100+ GB.

## Setup and client

See [docs/user/ai-server-setup.md](../user/ai-server-setup.md): `bootstrap.sh` on the server, `claude-local` on the dev machine.

Alternative: **OpenRouter** offers an Anthropic-compatible endpoint (`ANTHROPIC_BASE_URL=https://openrouter.ai/api`, `ANTHROPIC_AUTH_TOKEN=<key>`, `ANTHROPIC_API_KEY=""`). Prompt caching only works if requests keep going to the same provider. Claude Code can't send OpenRouter's `provider` routing field, so the provider has to be pinned in the OpenRouter account settings. Check the current OpenRouter docs before relying on this.

## Claude Code hardening

`modules/home-manager/generic/claude-code/` sets the following:

- **allow**: `Read`, `Glob`, `Grep`, `git status/diff/log/show`, `ls`
- **ask**: `Edit`, `Write`, `git commit/push`, `rm`, `mv`
- **deny**: `sudo`, `su`, `chmod`, `chown`, `sysctl`, `launchctl`, `pmset`, `diskutil`, `rm -rf`, force push, `reset --hard`, `curl`, `wget`; reading `.env*`, `*.pem`, `~/.ssh`, `~/.aws`, `~/.gnupg`, sops keys; editing its own `settings.json`
- **PreToolUse hook** (`guard-bash.sh`): permission rules only match the *start* of a command. The hook catches `ls; sudo x`, `echo $(curl …)`, `… | bash`, `bash -c`, `eval`, `env X=1 sudo`, `rm -r -f`, and similar. Exit code 2 blocks the call.

Limits: the hook is regex-based defense in depth, not a sandbox. Base64, variables and generated scripts get past it. For real isolation, also turn on Claude Code's sandbox (`sandbox.enabled`).

`mutableSettings = true` merges these keys into the existing `~/.claude/settings.json` instead of replacing it with a read-only symlink. The declared permission arrays replace the existing ones.

The module is imported **only on `amst`**. On the dev machines it would replace the current permissions and block `curl`/`wget`. Only import it there deliberately.
