{ pkgs, ... }:
let
  ports = {
    otlpGrpc = 4317;
    otlpHttp = 4318;
    # Loopback scrape target for the Prometheus below.
    metrics = 9464;
  };
in
{
  services.opentelemetry-collector = {
    enable = true;
    # The prometheus exporter is a contrib component, not core.
    package = pkgs.opentelemetry-collector-contrib;

    settings = {
      receivers.otlp.protocols = {
        grpc.endpoint = "0.0.0.0:${toString ports.otlpGrpc}";
        http.endpoint = "0.0.0.0:${toString ports.otlpHttp}";
      };

      processors.batch.timeout = "5s";

      exporters = {
        # Pull endpoint. Resource attributes (host.name, service.name) only
        # become labels when conversion is enabled — off by default, which
        # would leave every host's series with an identical label set.
        prometheus = {
          endpoint = "127.0.0.1:${toString ports.metrics}";
          resource_to_telemetry_conversion.enabled = true;
        };
        # The contrib `loki` exporter was removed upstream; Loki ingests
        # OTLP/HTTP natively at /otlp instead.
        "otlphttp/loki".endpoint = "http://127.0.0.1:3100/otlp";
        nop = { };
      };

      service.pipelines = {
        metrics = {
          receivers = [ "otlp" ];
          processors = [ "batch" ];
          exporters = [ "prometheus" ];
        };
        logs = {
          receivers = [ "otlp" ];
          processors = [ "batch" ];
          exporters = [ "otlphttp/loki" ];
        };
        # The tracker ships its own spans; nothing here stores them.
        traces = {
          receivers = [ "otlp" ];
          processors = [ "batch" ];
          exporters = [ "nop" ];
        };
      };
    };
  };

  # Only the OTLP listeners face the lab; 9464 stays on loopback.
  networking.firewall.allowedTCPPorts = [ ports.otlpGrpc ports.otlpHttp ];
}
