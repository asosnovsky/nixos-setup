{ config, looprail, pkgs, ... }:
let
  looprailPackages = looprail.packages.${pkgs.stdenv.hostPlatform.system};
  app = config.skyg.internalNetworkingMap.apps.caddy;
  nvr = config.skyg.internalNetworkingMap.apps.nvr;
  jellyfin = config.skyg.internalNetworkingMap.apps.jellyfin;
  immich = config.skyg.internalNetworkingMap.apps.immich;
  portainer = config.skyg.internalNetworkingMap.apps.portainer;
  buzz = config.skyg.internalNetworkingMap.apps.buzz;
  publicGitea = config.skyg.internalNetworkingMap.apps.public-gitea;
  umami = config.skyg.internalNetworkingMap.apps.umami;
  # Sent by release looprail binaries on telemetry posts. It ships in the
  # binary, so it only filters out scanners; it is not a secret.
  looprailTelemetryKey = "70c685d238cc9ec7229e557a8de7b0d25527b1a402805251";
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
        JELLYFIN_IP = jellyfin.ip;
        BUZZ_IP = buzz.ip;
        UMAMI_IP = umami.ip;
        LOOPRAIL_TELEMETRY_KEY = looprailTelemetryKey;
        K8S_INGRESS = k8sIngress;
      };
      volumes = [
        (if looprailPackages ? looprail-site then
          "${looprailPackages.looprail-site}:/srv/looprails:ro"
        else
          "${looprail}/docs/looprail.html:/srv/looprails/index.html:ro")
        "/var/lib/acme/${certDomain}/fullchain.pem:/etc/caddy/tls/fullchain.pem:ro"
        "/var/lib/acme/${certDomain}/key.pem:/etc/caddy/tls/key.pem:ro"
        "/var/lib/acme/${giteaCertDomain}/fullchain.pem:/etc/caddy/tls/gitea/fullchain.pem:ro"
        "/var/lib/acme/${giteaCertDomain}/key.pem:/etc/caddy/tls/gitea/key.pem:ro"
      ];
    };
  };
}
