{ config, skyg-secrets, ... }:
# Umami collects LoopRail's telemetry. Caddy on minipc3 sends it the public
# POST looprails.skyg.ca/t/v1 and the LAN-only dashboard. It runs in its own
# nspawn container with its own LAN address, and only Caddy can reach it.
let
  app = config.skyg.internalNetworkingMap.apps.umami;
  caddy = config.skyg.internalNetworkingMap.apps.caddy;
  appNetwork = config.skyg.internalNetworkingMap.appNetwork;
  parent = config.skyg.nixos.common.containers.networks.ipvlanLab.parent;
  # nspawn names the ipvlan link iv-<parent>.
  lanIf = "iv-${parent}";
  port = 3000;
  secretPath = "/run/secrets/umami-app-secret";
  hostStateVersion = config.system.stateVersion;
in
{
  age.secrets.umami-app-secret.file = skyg-secrets.umami-app-secret;

  containers.umami = {
    autoStart = true;
    # Own network: an ipvlan link on the LAN, like the docker apps get.
    privateNetwork = true;
    extraFlags = [ "--network-ipvlan=${parent}" ];
    bindMounts.${secretPath} = {
      hostPath = config.age.secrets.umami-app-secret.path;
      isReadOnly = true;
    };

    config = { lib, ... }: {
      system.stateVersion = hostStateVersion;

      networking = {
        useDHCP = false;
        interfaces.${lanIf}.ipv4.addresses = [{
          address = app.ip;
          prefixLength = lib.toInt (lib.last (lib.splitString "/" appNetwork.subnet));
        }];
        defaultGateway = { address = appNetwork.gateway; interface = lanIf; };
        nftables.enable = true;
        firewall = {
          enable = true;
          # Only Caddy may reach Umami, at most ~20 new connections a second.
          # Caddy opens one connection per telemetry request, so this caps requests.
          extraInputRules = ''
            ip saddr ${caddy.ip} tcp dport ${toString port} ct state new limit rate 20/second burst 100 packets accept
          '';
        };
      };

      # Postgres only on its local socket.
      services.postgresql.settings.listen_addresses = lib.mkForce "";

      services.umami = {
        enable = true;
        createPostgresqlDatabase = true;
        settings = {
          APP_SECRET_FILE = secretPath;
          HOSTNAME = "0.0.0.0";
          PORT = port;
          DISABLE_UPDATES = true;
          DISABLE_TELEMETRY = true;
          # looprail's User-Agent would look like a bot.
          DISABLE_BOT_CHECK = true;
        };
      };
    };
  };

  # A flood can't starve the rest of the host.
  systemd.services."container@umami".serviceConfig = {
    MemoryMax = "1G";
    CPUQuota = "100%";
  };
}
