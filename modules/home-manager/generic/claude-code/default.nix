# Hardened Claude Code settings for unattended use (e.g. on the AI server):
# reads are free, writes ask, system/secret/network access is denied, and a
# PreToolUse hook catches what the prefix-based rules miss.
{ pkgs, ... }:

let
  guardBash = pkgs.writeShellApplication {
    name = "claude-guard-bash";
    runtimeInputs = [ pkgs.jq pkgs.gnugrep ];
    text = builtins.readFile ./guard-bash.sh;
  };
in
{
  programs.claude-code = {
    enable = true;
    # Installed outside Nix: Homebrew cask on macOS (modules/macos/base/homebrew.nix),
    # metapac on Linux.
    package = null;
    # Merge into the existing ~/.claude/settings.json instead of replacing it with
    # a read-only store symlink, so /config keeps working. Declared keys win.
    mutableSettings = true;

    settings = {
      permissions = {
        allow = [
          "Read"
          "Glob"
          "Grep"
          "Bash(git status:*)"
          "Bash(git diff:*)"
          "Bash(git log:*)"
          "Bash(git show:*)"
          "Bash(ls:*)"
        ];
        ask = [
          "Edit"
          "Write"
          "Bash(git commit:*)"
          "Bash(git push:*)"
          "Bash(rm:*)"
          "Bash(mv:*)"
        ];
        deny = [
          "Bash(sudo:*)"
          "Bash(su:*)"
          "Bash(chmod:*)"
          "Bash(chown:*)"
          "Bash(sysctl:*)"
          "Bash(launchctl:*)"
          "Bash(pmset:*)"
          "Bash(diskutil:*)"
          "Bash(rm -rf:*)"
          "Bash(git push --force:*)"
          "Bash(git push -f:*)"
          "Bash(git reset --hard:*)"
          "Bash(curl:*)"
          "Bash(wget:*)"
          "Read(**/.env)"
          "Read(**/.env.*)"
          "Read(**/*.pem)"
          "Read(~/.ssh/**)"
          "Read(~/.aws/**)"
          "Read(~/.gnupg/**)"
          "Read(~/.config/sops/**)"
          "Edit(~/.claude/settings.json)"
        ];
      };

      hooks.PreToolUse = [{
        matcher = "Bash";
        hooks = [{
          type = "command";
          command = "${guardBash}/bin/claude-guard-bash";
        }];
      }];
    };
  };
}
