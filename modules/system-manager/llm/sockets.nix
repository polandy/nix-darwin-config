# Helpers for the sockets the bwrap sandbox reaches the host through
# (filter.nix: Ollama, sandbox-net.nix: egress proxy). Not a module.
{ cfg, pkgs }:

{
  # Socket for the sandbox, root-owned, only the agent user's group may connect.
  sandboxSocket = path: maxConnections: {
    listenStreams = [ path ];
    wantedBy = [ "sockets.target" ];
    socketConfig = {
      SocketUser = "root";
      SocketGroup = cfg.agentUser;
      SocketMode = "0660";
      DirectoryMode = "0755";
      Accept = true;
      MaxConnections = maxConnections;
    };
  };
  # Per-connection bridge from a sandbox socket to a localhost TCP port.
  socketBridge = target: {
    serviceConfig = {
      ExecStart = "${pkgs.socat}/bin/socat STDIO TCP:${target}";
      StandardInput = "socket";
      StandardOutput = "socket";
      StandardError = "journal";
      DynamicUser = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      RestrictAddressFamilies = "AF_INET";
      IPAddressDeny = "any";
      IPAddressAllow = "localhost";
    };
  };
}
