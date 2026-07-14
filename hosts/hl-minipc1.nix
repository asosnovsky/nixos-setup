{ config, ... }:
let
  ports = {
    audiobookshelf = 8000;
    nixServe = 5000;
    dockerRegistry = 5001;
    postgres = 5432;
    ssh = 22;
    iu = 1947;
  };
  gitea = {
    user = "gitea";
    group = "gitea";
    stateDir = "/var/lib/sosnovsky/gitea";
    sshPort = 2222;
    httpPort = 3000;
  };
  openPorts = [
    ports.nixServe
    ports.dockerRegistry
    ports.audiobookshelf
    gitea.sshPort
    gitea.httpPort
    ports.postgres
    ports.ssh
    ports.iu
  ];
in
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.server.admin.enable = true;
  skyg.server.exporters.enable = true;
  skyg.nixos.server.k3s.enable = false;
  skyg.networkDrives = {
    enable = true;
  };
  services.tailscale.enable = true;
  services.tailscale.disableTaildrop = true;
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.openFirewall = true;

  # # Nix Stores
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/minipc1.lab.internal.private";
    port = ports.nixServe;
  };
  # firmware updater
  services.fwupd.enable = true;
  # # Services
  skyg.nixos.server.services = {
    audiobookshelf = {
      enable = false;
      host = "0.0.0.0";
      openFirewall = true;
      port = ports.audiobookshelf;
      configDir = "/mnt/Data/audiobookshelf/config";
      metadataDir = "/mnt/Data/audiobookshelf/metadata";
    };
  };
  services.dockerRegistry = {
    enable = true;
    storagePath = "/mnt/Data/docker-registry";
    port = ports.dockerRegistry;
    openFirewall = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };
  services.gitea = {
    enable = true;
    appName = "Sosnovsky gitea";
    stateDir = gitea.stateDir;
    user = gitea.user;
    group = gitea.group;
    settings = {
      server = {
        SSH_USER = gitea.user;
        DOMAIN = "minipc1.lab.internal";
        HTTP_PORT = gitea.httpPort;
        SSH_PORT = gitea.sshPort;
        DISABLE_SSH = false;
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  skyg.nixos.common.container-services.iu = {
    services = {
      db = {
        image = "postgres:18";
        ports = [
          "${toString ports.postgres}:5432"
        ];
        volumes = [
          "/var/lib/iu:/opt/data"
        ];
        environmentFiles = [ config.age.secrets.iu-project.path ];
        networks = [ "main" ];
      };
      iu = {
        image = "minipc1.lab.internal:5001/iu:2026.07.12-ac2c604";
        ports = [
          "${toString ports.iu}:1947"
        ];
        volumes = [
        ];
        environmentFiles = [
        ];
        networks = [
          "main"
        ];
      };
    };
  };

  # Certbot TLS service
  skyg.server.dns.certbot = {
    enable = false;
    email = "admin@skyg.ca";
    publicDomains = [
      ".*skyg.ca"
      ".*home.sosnovsky.ca"
    ];
  };

  # Firewall
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
