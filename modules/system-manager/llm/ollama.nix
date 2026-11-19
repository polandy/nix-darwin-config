{ config, lib, ... }:

let
  cfg = config.llm;
  # ollama.service comes from the Arch package; system-manager would replace a
  # unit defined in systemd.services completely, so it only gets drop-ins.
  dropIn = name: text: {
    "systemd/system/ollama.service.d/${name}.conf".text = "[Service]\n" + text;
  };
in
{
  config = lib.mkIf cfg.enable {
    # Local LLM work wins CPU against end-to-end test containers, which may run
    # next to it (owner decision 4.2 a). Docker: --cgroup-parent e2e.slice.
    systemd.slices.llm = {
      description = "Local LLM (ollama, bench, pilot)";
      sliceConfig.CPUWeight = 200;
    };
    systemd.slices.e2e = {
      description = "E2E test containers";
      sliceConfig.CPUWeight = 50;
    };

    environment.etc =
      # Hosts other than localhost (host-local allow files, see firewall.nix)
      # need 0.0.0.0. Once the Docker sandbox is gone and none is left,
      # 127.0.0.1 is enough.
      dropIn "override" ''
        Environment="OLLAMA_HOST=0.0.0.0:${toString cfg.ports.ollama}"
      ''
      // dropIn "llm-tuning" ''
        Environment=OLLAMA_FLASH_ATTENTION=1
        Environment=OLLAMA_KV_CACHE_TYPE=q8_0
        Environment=OLLAMA_NUM_PARALLEL=1
      ''
      # Takes effect on the next ollama restart.
      // dropIn "llm-slice" ''
        Slice=llm.slice
      '';
  };
}
