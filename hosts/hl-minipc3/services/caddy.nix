{ config, ... }:
let
  app = config.skyg.internalNetworkingMap.apps.caddy;
  nvr = config.skyg.internalNetworkingMap.apps.nvr;
  jellyfin = config.skyg.internalNetworkingMap.apps.jellyfin;
  immich = config.skyg.internalNetworkingMap.apps.immich;
  portainer = config.skyg.internalNetworkingMap.apps.portainer;
  buzz = config.skyg.internalNetworkingMap.apps.buzz;
  publicGitea = config.skyg.internalNetworkingMap.apps.public-gitea;
  certDomain = "home.sosnovsky.ca";
  giteaCertDomain = "gitea.skyg.ca";
  # k8s Traefik ingress — fallback for hosts caddy doesn't handle itself.
  k8sIngress = "10.0.100.1";
in
{
  skyg.nixos.common.container-services.caddy = {
    enable = true;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    services.caddy = {
      image = "livekit/caddyl4:v2.11.3";
      extraConfig = {
        entrypoint = [ "caddy" ];
        dns = [ config.skyg.internalNetworkingMap.appNetwork.gateway ];
      };
      command = [ "run" "--config" "/etc/caddy/Caddyfile" "--adapter" "caddyfile" ];
      networks.lan.ipv4_address = app.ip;
      files."/etc/caddy/Caddyfile" = ''
        {
          layer4 {
            :22 {
              route {
                proxy ${publicGitea.ip}:22
              }
            }
          }
        }
        nvr.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy ${nvr.ip}:11080
        }
        jellyfin.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy bigbox1.lab.internal:8096
        }
        immich.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy ${immich.ip}:2283
        }
        portainer.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy ${portainer.ip}:9000
        }
        gitea.skyg.ca {
          tls /etc/caddy/tls/gitea/fullchain.pem /etc/caddy/tls/gitea/key.pem
          reverse_proxy ${publicGitea.ip}:80
        }
        # Buzz: straight to its own caddy. LAN (10/8) + Tailscale only.
        buzz.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          @notlan not remote_ip 10.0.0.0/8 100.64.0.0/10
          abort @notlan
          reverse_proxy https://${buzz.ip}:443 {
            header_up Host {http.request.host}
            transport http {
              tls
              tls_server_name {http.request.host}
            }
          }
        }
        # Fallback: any other *.home.sosnovsky.ca host goes to the k8s Traefik.
        # Host + SNI are preserved so Traefik routes on the original hostname.
        *.home.sosnovsky.ca {
          tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
          reverse_proxy https://${k8sIngress}:443 {
            header_up Host {http.request.host}
            transport http {
              tls
              tls_server_name {http.request.host}
            }
          }
        }
      '';
      volumes = [
        "/var/lib/acme/${certDomain}/fullchain.pem:/etc/caddy/tls/fullchain.pem:ro"
        "/var/lib/acme/${certDomain}/key.pem:/etc/caddy/tls/key.pem:ro"
        "/var/lib/acme/${giteaCertDomain}/fullchain.pem:/etc/caddy/tls/gitea/fullchain.pem:ro"
        "/var/lib/acme/${giteaCertDomain}/key.pem:/etc/caddy/tls/gitea/key.pem:ro"
      ];
    };
  };
}
