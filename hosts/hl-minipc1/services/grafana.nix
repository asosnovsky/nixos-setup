{ config, skyg-secrets, ... }:
let
  ports = {
    grafana = 3001;
    prometheus = 9090;
    loki = 3100;
  };
in
{
  age.secrets.grafana-secret-key = {
    file = skyg-secrets.grafana-secret-key;
    owner = "grafana";
    group = "grafana";
  };

  services.grafana = {
    enable = true;
    openFirewall = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = ports.grafana;
      };
      security.secret_key = "$__(file){${config.age.secrets.grafana-secret-key.path}}";
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString ports.prometheus}";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString ports.loki}";
        }
      ];
    };
  };
}
