{ config, ... }:
let
  app = config.skyg.internalNetworkingMap.apps.caddy;
  nvr = config.skyg.internalNetworkingMap.apps.nvr;
  jellyfin = config.skyg.internalNetworkingMap.apps.jellyfin;
  portainer = config.skyg.internalNetworkingMap.apps.portainer;
  certDomain = "home.sosnovsky.ca";
in
{
  skyg.nixos.common.container-services.caddy = {
    enable = true;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    services.caddy = {
      image = "caddy:2-alpine";
      networks.lan.ipv4_address = app.ip;
      files."/etc/caddy/Caddyfile" = ''
        nvr.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy ${nvr.ip}:11080
        }
        jellyfin.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy bigbox1.lab.internal:8096
        }
        portainer.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy ${portainer.ip}:9000
        }
      '';
      volumes = [
        "/var/lib/acme/${certDomain}/fullchain.pem:/etc/caddy/tls/fullchain.pem:ro"
        "/var/lib/acme/${certDomain}/key.pem:/etc/caddy/tls/key.pem:ro"
      ];
    };
  };
}
