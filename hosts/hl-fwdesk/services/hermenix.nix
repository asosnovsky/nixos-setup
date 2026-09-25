{ ... }:
let
  ports = {
    hermes = 8642;
    hermesDashboard = 9119;
    hermesCache = 5001;
    ollama = 11434;
    ds4 = 8000;
  };
in
{
  services.hermenix = {
    enable = true;
    disk.baseDir = "/var/lib/hermes-vm";
    disk.stateSize = "60G";
    network = {
      bridged = false;
      externalInterface = "enp191s0";
      lanAddress = "10.0.101.101";
      hostLanAddress = "10.0.10.11";
      lanGateway = "10.0.0.1";
    };
    vcpu = 3;
    mem = 5000;
    hermesHome = "/var/lib/hermes/.hermes";
    hostCache.port = ports.hermesCache;
    hostAccess = [
      { port = ports.ollama; }
      { port = ports.ds4; }
    ];
    lanAccess = [
      { address = "10.0.12.1"; port = 80; }
      { address = "10.0.101.0/24"; port = 80; }
      { address = "10.0.101.0/24"; port = 443; }
      { address = "10.0.101.3"; port = 3000; }
      { address = "10.0.101.3"; port = 8080; }
      { address = "10.0.101.3"; port = 9102; }
      { address = "10.0.10.6"; port = 3000; }
    ];
    publish = [
      { hostPort = ports.hermes; guestPort = 8642; }
      { hostPort = ports.hermesDashboard; guestPort = 9119; }
    ];
  };
}
