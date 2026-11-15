# Client side of the AI server: `claude-local` starts Claude Code against the
# LiteLLM proxy on amst instead of Anthropic. Import per dev host and set
# my.aiClient.url. See docs/user/ai-server-setup.md.
{ config, lib, ... }:

let
  cfg = config.my.aiClient;
in
{
  options.my.aiClient.url = lib.mkOption {
    type = lib.types.str;
    example = "https://amst.tail1234.ts.net";
    description = "HTTPS URL of the AI server's proxy, as shown by `tailscale serve status` on amst.";
  };

  config.programs.fish.functions.claude-local = {
    description = "Claude Code against the local AI server";
    # LiteLLM runs without a master key, but Claude Code needs some token.
    body = ''
      ANTHROPIC_BASE_URL=${cfg.url} ANTHROPIC_AUTH_TOKEN=dummy ANTHROPIC_API_KEY= claude $argv
    '';
  };
}
