{ config, ... }:
{
  services.skyg-linux-tracker = {
    enable = true;
    bind = "0.0.0.0";
    openFirewall = true;
    docker.enable = config.virtualisation.docker.enable;
    # Reachable only by its lab FQDN; the short name does not resolve.
    allowedHosts = [ "minipc2.lab.internal" ];
    # OTLP out to the collector on minipc1.
    settings.otel = {
      enabled = true;
      endpoint = "http://minipc1.lab.internal:4317";
      protocol = "grpc";
      export_logs = true;
    };
  };
}
