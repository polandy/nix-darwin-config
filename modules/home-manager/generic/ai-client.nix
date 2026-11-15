# Client side of the AI server: `claude-local` starts Claude Code against the
# LiteLLM proxy on amst instead of Anthropic. Import per dev host and set
# my.aiClient.url. See docs/user/ai-server-setup.md.
{ config, lib, ... }:

let
  cfg = config.my.aiClient;
in
{
  options.my.aiClient = {
    url = lib.mkOption {
      type = lib.types.str;
      example = "https://amst.tail1234.ts.net";
      description = "HTTPS URL of the AI server's proxy, as shown by `tailscale serve status` on amst.";
    };
    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/.config/ai-client/token";
      description = ''
        File with the LiteLLM master key from amst
        (~/.config/ai-server/litellm-master-key there). Can also be a sops secret path.
      '';
    };
  };

  config.programs.fish.functions.claude-local = {
    description = "Claude Code against the local AI server";
    body = ''
      if not test -r ${lib.escapeShellArg cfg.tokenFile}
        echo "claude-local: token file ${cfg.tokenFile} missing, see docs/user/ai-server-setup.md" >&2
        return 1
      end
      set -lx ANTHROPIC_BASE_URL ${lib.escapeShellArg cfg.url}
      set -lx ANTHROPIC_AUTH_TOKEN (cat ${lib.escapeShellArg cfg.tokenFile})
      set -lx ANTHROPIC_API_KEY ""
      claude $argv
    '';
  };
}
