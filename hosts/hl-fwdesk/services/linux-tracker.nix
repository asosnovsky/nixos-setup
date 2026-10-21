{ config, lib, skyg-secrets, ... }:
let
  # Hosts this primary tracker consolidates.
  peers = [ "minipc1" "minipc2" "minipc3" "bigbox1" "bigbox2" "terra1" ];
  secretName = peer: "linux-tracker-peer-${peer}";
in
{
  age.secrets = lib.genAttrs (map secretName peers) (name: {
    file = skyg-secrets.${name};
    owner = "root";
    mode = "0400";
  });

  services.skyg-linux-tracker = {
    enable = true;
    bind = "0.0.0.0";
    openFirewall = true;
    docker.enable = config.virtualisation.docker.enable;
    # The Hermes VM reaches this host at 10.77.0.1.
    allowedHosts = [ "fwdesk.lab.internal" "10.77.0.1" ];
    # Primary: one endpoint for the whole lab (Hermes only talks to this one).
    peers = {
      enable = true;
      peers = lib.genAttrs peers (peer: {
        url = "http://${peer}.lab.internal:1984";
        tokenFile = config.age.secrets.${secretName peer}.path;
        # Trackers have no TLS; token travels in the clear on the lab LAN.
        allowPlainHttp = true;
      });
    };
    # OTLP out to the collector on minipc1.
    settings.otel = {
      enabled = true;
      endpoint = "http://minipc1.lab.internal:4317";
      protocol = "grpc";
      export_logs = true;
    };
  };
}
