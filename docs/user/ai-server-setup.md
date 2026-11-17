# AI server setup (Mac Studio, host `amst`)

Step-by-step setup of the headless AI server described in [docs/dev/ai-server.md](../dev/ai-server.md), and of the dev machines that use it. Most of it is automated. The table shows what is left to do by hand.

| Step | Where | How |
|------|-------|-----|
| 1. macOS setup assistant | server, with screen + keyboard | **manual**, ~15 min |
| 2. Bootstrap | server | **`bootstrap.sh`**: a few prompts (sudo, Tailscale login) |
| 3. Wait for the model | server | automatic: `ai-server-check` reports progress |
| 4. SSH key, tailnet ACL, go headless | dev machine, Tailscale admin console | **manual**, ~10 min |
| 5. Client | dev machine | **2 lines of Nix**, copy the key, `just switch` |

Everything else is applied by nix-darwin on every `just switch`: power settings, SSH, Tailscale daemon, GPU memory limit, the LiteLLM master key, and the MLX and LiteLLM daemons.

> As long as the `amst` config only lives on the branch `feat/ai-server`, replace `main` with `feat/ai-server` in the URLs below and run the script with `REF=feat/ai-server`.

## 1. macOS setup assistant (manual)

Connect a screen and keyboard once, and preferably Ethernet.

1. Run through the setup assistant:
   - **Account:** create the admin user **`andy`** (the config expects `/Users/andy`).
   - **FileVault:** **do not turn it on.** With FileVault, the Mac would stop at the unlock screen after every power cut. The bootstrap script aborts if FileVault is on.
   - **Apple ID:** can be skipped. The server needs no App Store apps.
2. Install pending macOS updates: System Settings → General → Software Update.

## 2. Bootstrap (automated)

In Terminal on the server:

```bash
curl -fsSLO https://raw.githubusercontent.com/polandy/nix-darwin-config/main/hosts/amst/bootstrap.sh
less bootstrap.sh     # read before running
bash bootstrap.sh
```

The script is idempotent. If it aborts, fix the cause and run it again: finished steps are skipped. It does the following:

1. Checks that FileVault is off.
2. Installs Homebrew (which brings the Xcode Command Line Tools and git) and Nix (Determinate installer).
3. Clones the repo to `~/dev/nix-darwin-config`.
4. Runs the first `darwin-rebuild switch` for `.#amst`, with the nix-darwin version from `flake.lock`. This also sets the hostname and creates the LiteLLM master key, so later updates are just `just switch`.
5. Runs `tailscale up` and `tailscale serve`, exposing the LiteLLM proxy as `https://amst.<tailnet>.ts.net`.
6. Prints the URL and where the key is, then runs `ai-server-check`.

You will be asked for:
- **your password**, once (sudo);
- a **Tailscale login**: open the printed URL and log in;
- possibly **enabling HTTPS/Serve for the tailnet**: open the printed URL and confirm. This happens only once per tailnet.

If the switch aborts with *"Unexpected files in /etc"*, rename the files as the error message suggests (to `*.before-nix-darwin`) and run the script again.

## 3. Wait for the model (automatic)

On first start, `uvx` installs Python 3.12 and mlx-lm, then `mlx_lm.server` downloads the model, which is 100+ GB. Check the progress:

```bash
tail -f ~/Library/Logs/mlx-server.log
du -sh ~/.cache/huggingface
ai-server-check
```

`ai-server-check` checks FileVault, the GPU limit, pmset, both daemons, the MLX API (while it is down, it shows how much of the model has been downloaded), the master key, a real Anthropic API request through LiteLLM, and Tailscale Serve. Each failed check prints what to do next. The setup is done when it ends with **All checks passed.**

## 4. SSH key, then go headless (manual)

The dev machine must be in the same tailnet. On the dev machine:

```bash
ssh-copy-id andy@amst      # asks for the password once
ssh andy@amst ai-server-check
```

In the [Tailscale admin console](https://login.tailscale.com/admin):

1. **Machines → amst → Disable key expiry: leave it off.** With expiry on, you re-authenticate every 180 days, but a stolen disk stops being a valid tailnet device by itself. Re-authenticating is `ssh andy@amst sudo tailscale up`.
2. **Tag the machine** (e.g. `tag:ai-server`) and **restrict access in the ACL** to your own devices, for example:

   ```json
   "grants": [
     { "src": ["autogroup:member"], "dst": ["tag:ai-server"], "ip": ["443", "22"] }
   ]
   ```

   The default ACL lets every device in the tailnet, including shared-in ones, reach the proxy. The master key still protects it, but the ACL keeps everyone else from even trying.

Then unplug the screen and keyboard. From now on, everything is done over SSH.

## 5. Client: Claude Code on the dev machine

In the dev host's `hosts/<host>/home.nix`:

```nix
imports = [
  # ...
  ../../modules/home-manager/generic/ai-client.nix
];
my.aiClient.url = "https://amst.<tailnet>.ts.net";   # from the bootstrap output / `tailscale serve status`
```

Copy the master key from the server (the client reads it from `~/.config/ai-client/token`; set `my.aiClient.tokenFile` to use a sops secret instead):

```bash
mkdir -p ~/.config/ai-client
(umask 077; ssh andy@amst cat .config/ai-server/litellm-master-key > ~/.config/ai-client/token)
```

Then run `just switch`. After that:

```bash
claude-local          # Claude Code against the AI server
claude                # unchanged: Claude Code against Anthropic
```

## Operation

| Task | How |
|------|-----|
| Update config / packages | On the server: `cd ~/dev/nix-darwin-config && git pull && just switch` |
| Change the model | Edit `my.aiServer.model` in `hosts/amst/default.nix`, then `just switch`. The new model downloads on the next start |
| Update mlx-lm | Set `my.aiServer.mlx.version`, then `just switch` |
| Logs | `~/Library/Logs/mlx-server.log`, `~/Library/Logs/litellm.log` |
| Restart a service | `sudo launchctl kickstart -k system/org.nixos.mlx-server` (or `org.nixos.litellm`) |
| Status | `ai-server-check` |
| Rotate the master key | On the server: `rm ~/.config/ai-server/litellm-master-key && just switch && sudo launchctl kickstart -k system/org.nixos.litellm`, then copy it to the clients again |
| Planned reboot | `sudo shutdown -r now` (with FileVault on: `sudo fdesetup authrestart`, which skips the unlock screen once) |
| Disk space | `du -sh ~/.cache/huggingface/hub/*`; remove models you no longer use with `rm -rf ~/.cache/huggingface/hub/models--<org>--<name>` |

## Troubleshooting

| Symptom | Cause / fix |
|---------|-------------|
| Server unreachable after a power cut | Is FileVault on? Then it waits at the unlock screen: connect a screen, unlock, then `sudo fdesetup disable` |
| `mlx-server` restarts in a loop | Model too large for `gpuWiredLimitMb`, or the download was interrupted: check the log, delete the model folder in `~/.cache/huggingface/hub` and restart |
| `claude-local`: connection error | Dev machine not in the tailnet, not allowed by the ACL, or `my.aiClient.url` wrong: compare with `tailscale serve status` on the server |
| `claude-local`: 401 / authentication error | Token file outdated (key rotated): copy it again (step 5) |
| `mlx-server` log: Python version / resolution error | uv must use its own Python 3.12; check that the daemon has `UV_PYTHON_PREFERENCE=only-managed` (`sudo launchctl print system/org.nixos.mlx-server`) |
| `ai-server-check` reports FAIL for Tailscale or the daemons, but everything works | Some queries may need root: compare with `sudo tailscale status` and `sudo launchctl print system/org.nixos.<name>` |
| Very slow answers | Context too long for the KV cache, or the model doesn't fit fully into GPU memory: use a smaller model or a lower bit width |
