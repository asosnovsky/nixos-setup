{ config, ... }:
{
  services.skyg-linux-tracker = {
    enable = true;
    bind = "0.0.0.0";
    openFirewall = true;
    docker.enable = config.virtualisation.docker.enable;
    # Reachable only by its lab FQDN; the short name does not resolve.
    allowedHosts = [ "minipc1.lab.internal" ];
    # OTLP out to the collector on this box (see ./otel-collector.nix).
    settings.otel = {
      enabled = true;
      endpoint = "http://127.0.0.1:4317";
      protocol = "grpc";
      export_logs = true;
    };
  };
}
