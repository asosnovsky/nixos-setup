{ ... }:
let
  ports = { prometheus = 9090; };
in
{
  services.prometheus = {
    enable = true;
    port = ports.prometheus;
    listenAddress = "0.0.0.0";
    retentionTime = "48h";

    scrapeConfigs = [
      {
        job_name = "lab-trackers";
        static_configs = [{ targets = [ "127.0.0.1:9464" ]; }];
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [ ports.prometheus ];
}
