{ user }:
{ ... }:
let
  ports = {
    audiobookshelf = 8000;
    nixServe = 5000;
    dockerRegistry = 5001;
  };
  gitea = {
    user = "gitea";
    group = "gitea";
    stateDir = "/var/lib/sosnovsky/gitea";
    sshPort = 2222;
    httpPort = 3000;
    sshKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPXJ3NWIHsFMKhNp5FUSJcZU4eevhKyfcHR9dyCSbo19 ari@fwbook";
  };
  openPorts = [
    ports.nixServe
    ports.dockerRegistry
    ports.audiobookshelf
    gitea.sshPort
    gitea.httpPort
    22
  ];
in
{
  imports = [ ./hl-minipc1.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
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
      metadtaDir = "/mnt/Data/audiobookshelf/metadata";
    };
  };
  services.dockerRegistry = {
    enable = false;
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
  # Firewall
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}

