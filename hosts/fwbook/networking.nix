{ ... }:
let
  openPorts = [
    8000
    8001
  ];
in
{
  fileSystems."/mnt/EightTerra/FamilyStorage" = {
    device = "tnas1.lab.internal:/mnt/EightTerra/FamilyStorage";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
  networking.hosts = {
    "0.0.0.0" = [
      "auth.me.internal"
      "me.internal"
      "me.local"
      "api.me.internal"
    ];
    "127.0.0.1" = [
      "fwbook"
      "auth.me.internal"
      "me.internal"
      "me.local"
      "api.me.internal"
    ];
  };
}
