#!/usr/bin/env bash
# First-time setup of the AI server (host amst) on a freshly installed Mac.
# Run as the admin user (andy), not as root. Idempotent: every step is skipped
# if it is already done, so it can simply be run again after a failure.
# See docs/user/ai-server-setup.md.
#
#   curl -fsSLO https://raw.githubusercontent.com/polandy/nix-darwin-config/main/hosts/amst/bootstrap.sh
#   less bootstrap.sh && bash bootstrap.sh
#
# Environment: REF (git branch/tag to check out, default main),
#              REPO_DIR (default ~/dev/nix-darwin-config).
set -euo pipefail

REF=${REF:-main}
REPO_URL=https://github.com/polandy/nix-darwin-config.git
REPO_DIR=${REPO_DIR:-$HOME/dev/nix-darwin-config}
HOST=amst
NIX=/nix/var/nix/profiles/default/bin/nix

step() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
skip() { printf '    already done: %s\n' "$*"; }
die() {
  printf '\033[31mError:\033[0m %s\n' "$*" >&2
  exit 1
}

[ "$(uname)" = Darwin ] || die "run this on the Mac"
[ "$(id -u)" -ne 0 ] || die "run as your admin user, not as root (the script uses sudo itself)"

step "sudo (asked once, kept alive while the script runs)"
sudo -v
while true; do
  sudo -n true
  sleep 50
  kill -0 "$$" 2>/dev/null || exit
done 2>/dev/null &

step "FileVault"
if fdesetup isactive >/dev/null 2>&1; then
  die "FileVault is on: an unattended reboot would stop at the unlock screen.
       Run 'sudo fdesetup disable', wait until 'fdesetup status' reports
       decryption is finished, then run this script again."
fi
skip "FileVault is off"

step "Homebrew (also installs the Xcode Command Line Tools, which bring git)"
if [ -x /opt/homebrew/bin/brew ]; then
  skip "Homebrew"
else
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
eval "$(/opt/homebrew/bin/brew shellenv)"

step "Nix (Determinate Systems installer)"
if [ -x "$NIX" ]; then
  skip "Nix"
else
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
fi

step "Repository $REPO_URL ($REF) in $REPO_DIR"
if [ -d "$REPO_DIR/.git" ]; then
  skip "clone (not touching existing checkout; current branch: $(git -C "$REPO_DIR" branch --show-current))"
else
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone --branch "$REF" "$REPO_URL" "$REPO_DIR"
fi

step "nix-darwin: first switch to .#$HOST (power, SSH, Tailscale, GPU limit, MLX + LiteLLM daemons)"
# Also sets the hostname, so later updates work with plain `just switch`.
# If this aborts with "Unexpected files in /etc", follow the rename the error
# message suggests and run the script again.
sudo "$NIX" run nix-darwin -- switch --flake "$REPO_DIR#$HOST"
export PATH=/run/current-system/sw/bin:$PATH

step "Tailscale login"
if tailscale status >/dev/null 2>&1; then
  skip "Tailscale is logged in"
else
  echo "    Open the URL printed below and log in to your tailnet."
  sudo tailscale up
fi

proxy_port=$("$NIX" eval --raw "$REPO_DIR#darwinConfigurations.$HOST.config.my.aiServer.proxy.port")
step "Expose the LiteLLM proxy (:$proxy_port) on the tailnet with HTTPS"
if tailscale serve status 2>/dev/null | grep -q "127.0.0.1:$proxy_port"; then
  skip "tailscale serve"
else
  echo "    If Tailscale asks to enable HTTPS/Serve for the tailnet, open the URL and confirm."
  sudo tailscale serve --bg "$proxy_port"
fi

step "Health check"
if ai-server-check; then
  echo
  echo "Setup complete."
else
  echo
  echo "Not everything is up yet. On first start the model is still downloading (100+ GB);"
  echo "watch ~/Library/Logs/mlx-server.log and run 'ai-server-check' again later."
fi
