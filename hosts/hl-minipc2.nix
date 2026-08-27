{ pkgs, config, ... }:
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.server.exporters.enable = true;
  skyg.networkDrives = {
    enable = true;
  };

  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Disable firewall
  networking.firewall.enable = false;

  # Scrypted container service group
  skyg.nixos.common.container-services.scrypted = {
    enable = true;
    autoUpdate.enable = true;
    services.scrypted = {
      image = "ghcr.io/koush/scrypted";
      volumes = [
        "/var/run/dbus:/var/run/dbus"
        "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
        "/opt/homelab/scrypted/db:/server/volume"
        "scrypted-nvr:/nvr"
      ];
      environment.SCRYPTED_NVR_VOLUME = "/nvr";
      network_mode = "host";
    };
    volumes = {
      scrypted-nvr = {
        driver = "local";
        driver_opts = {
          type = "nfs";
          o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
          device = ":/mnt/OneT/NVR";
        };
      };
    };
  };

  # Drawdb
  skyg.nixos.common.container-services.drawdb = {
    enable = true;
    autoUpdate.enable = true;
    services.drawdb = {
      image = "ghcr.io/drawdb-io/drawdb:latest";
      ports = [
        "3000:80"
      ];
    };
  };

  # Portainer Service
  skyg.nixos.common.container-services.portainer = {
    enable = true;
    autoUpdate.enable = true;
    services.portainer = {
      image = "portainer/portainer-ce:lts";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "portainer_data:/data"
      ];
      ports = [
        "9443:9443"
        "8000:8000"
      ];
    };
    volumes = {
      portainer_data = {
        name = "portainer_data";
      };
    };
  };

  age.secrets.stack1.file = ../secrets/stack1.age;
  skyg.nixos.common.container-services.stack1 = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.stack1.path;
  };
  age.secrets.stack2.file = ../secrets/stack2.age;
  skyg.nixos.common.container-services.stack2 = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.stack2.path;
  };

  # Scrypted backup timer (image auto-update handled by container-services autoUpdate)
  skyg.server.timers = {
    scrypted-backups = {
      OnCalendar = "daily";
      wantedBy = [ "homelab-terra1-Data-apps.mount" ];
      script = ''
        set -eu
        ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/homelab/scrypted /homelab/terra1/Data/apps/
      '';
    };
  };
}
