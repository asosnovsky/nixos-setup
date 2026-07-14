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

  # Dockge container service group
  skyg.nixos.common.container-services.dockge = {
    enable = true;
    services.dockge = {
      image = "louislam/dockge:1";
      ports = [ "5001:5001" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "dockge-data:/app/data"
        "dockge-stacks:/opt/stacks"
      ];
      environment.DOCKGE_STACKS_DIR = "/opt/stacks";
    };
    volumes = {
      dockge-data = {
        driver = "local";
        driver_opts = {
          type = "nfs";
          o = "addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
          device = ":/mnt/Data/apps/arrs/dockge/data";
        };
      };
      dockge-stacks = {
        driver = "local";
        driver_opts = {
          type = "nfs";
          o = "addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
          device = ":/mnt/Data/apps/arrs/dockge/stacks";
        };
      };
    };
  };

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
