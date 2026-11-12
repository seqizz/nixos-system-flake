# Baseline systemd sandboxing for the server's own network daemons.
# The filesystem is read-only to the service (ProtectSystem=strict), so each
# service must list the paths it writes to in ReadWritePaths.
# Merge with `hardening // { ... }` in serviceConfig.
{
  ProtectSystem = "strict";
  ProtectHome = true;
  PrivateTmp = true;
  PrivateDevices = true;
  NoNewPrivileges = true;
  ProtectKernelTunables = true;
  ProtectKernelModules = true;
  ProtectKernelLogs = true;
  ProtectControlGroups = true;
  ProtectClock = true;
  ProtectHostname = true;
  RestrictAddressFamilies = [
    "AF_INET"
    "AF_INET6"
    "AF_UNIX"
  ];
  RestrictNamespaces = true;
  RestrictRealtime = true;
  RestrictSUIDSGID = true;
  LockPersonality = true;
  SystemCallArchitectures = "native";
  CapabilityBoundingSet = "";
}
