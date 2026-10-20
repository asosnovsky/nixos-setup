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
      # Routes live in ./Caddyfile; IPs come in as env vars.
      files."/etc/caddy/Caddyfile" = builtins.readFile ./Caddyfile;
      environment = {
        GITEA_IP = publicGitea.ip;
        NVR_IP = nvr.ip;
        IMMICH_IP = immich.ip;
        PORTAINER_IP = portainer.ip;
        BUZZ_IP = buzz.ip;
        K8S_INGRESS = k8sIngress;
      };
      volumes = [
        "/var/lib/acme/${certDomain}/fullchain.pem:/etc/caddy/tls/fullchain.pem:ro"
        "/var/lib/acme/${certDomain}/key.pem:/etc/caddy/tls/key.pem:ro"
        "/var/lib/acme/${giteaCertDomain}/fullchain.pem:/etc/caddy/tls/gitea/fullchain.pem:ro"
        "/var/lib/acme/${giteaCertDomain}/key.pem:/etc/caddy/tls/gitea/key.pem:ro"
      ];
    };
  };
}
