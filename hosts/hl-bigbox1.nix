{ pkgs, config, ... }:
{
  skyg = {
    user.enable = true;
    server.admin.enable = true;
    server.exporters.enable = true;
    server.timers = {
      jellyfin-backups = {
        OnCalendar = "daily";
        wantedBy = [
          "homelab-terra1-Data-apps.mount"
        ];
        script = ''
          set -eu
          ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/jellyfin /homelab/terra1/Data/apps/
        '';
      };
    };
    nixos = {
      desktop = {
        enable = false;
        gnome.enable = false;
      };
      common.ssh-server.enable = true;
      common.containers.openMetricsPort = true;
      common.hardware = {
        nvidia.enable = true;
        amdgpu.enable = true;
        udevrules.coraltpu.enable = true;
      };
      server.k3s = {
        enable = false;
        envPath = "/opt/k3s/k3s.env";
      };
      server.services = {
        ai.enable = true;
        jellyfin.enable = false;
      };
    };
    networkDrives.enable = true;
  };

  # Dockge container service group
  skyg.nixos.common.container-services.jellyfin = {
    enable = true;
    autoUpdate.enable = true;
    services = {
      jellyfin = {
        image = "jellyfin/jellyfin";
        deploy = {
          resources = {
            reservations = {
              devices = [
                {
                  driver = "cdi";
                  device_ids = [ "nvidia.com/gpu=all" ];
                  capabilities = [ "gpu" ];
                }
              ];
            };
          };
        };
        volumes = [
          "/opt/jellyfin:/mnt/apps/jellyfin"
          "torrents:/torrents"
          "family-videos:/family-videos"
        ];
        devices = [ "/dev/dri:/dev/dri" ];
        restart = "always";
        healthcheck = {
          test = "curl --fail http://0.0.0.0:8096 || exit 1";
          interval = "60s";
          timeout = "20s";
          start_period = "30s";
        };
        environment = {
          JELLYFIN_DATA_DIR = "/mnt/apps/jellyfin/data";
          JELLYFIN_CACHE_DIR = "/mnt/apps/jellyfin/cache";
          JELLYFIN_CONFIG_DIR = "/mnt/apps/jellyfin/config";
          NVIDIA_VISIBLE_DEVICES = "all";
        };
        ports = [ "8096:8096" ];
      };
    };
    volumes = {
      torrents = {
        driver_opts = {
          "type" = "nfs";
          "o" = "addr=tnas1.lab.internal,nfsvers=4";
          "device" = ":/mnt/EightTerra/DownloadedTorrents";
        };
      };
      family-videos = {
        driver_opts = {
          "type" = "nfs";
          "o" = "addr=tnas1.lab.internal,nfsvers=4";
          "device" = ":/mnt/EightTerra/FamilyStorage/Video";
        };
      };
      jellyfin = {
        driver_opts = {
          "type" = "nfs";
          "o" = "addr=tnas1.lab.internal,nfsvers=4";
          "device" = ":/mnt/Data/apps/jellyfin";
        };
      };
    };
  };

  services.displayManager.defaultSession = "gnome";
  services.displayManager.gdm.enable = false;

  services.autosuspend.enable = false;
  services.displayManager.autoLogin = {
    enable = true;
    user = config.skyg.user.name;
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  # Disable auto-suspend
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.displayManager.gdm.autoSuspend = false;
  services.displayManager.gdm.autoLogin.delay = 0;
  # Remote Desktop
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;
  # Sunshine
  services.sunshine = {
    enable = false;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };
  # security.wrappers.sunshine = {
  #   owner = "root";
  #   group = "root";
  #   capabilities = "cap_sys_admin+p";
  #   source = "${pkgs.sunshine}/bin/sunshine";
  # };
  #  Firewall & permissions
  networking.firewall.enable = false;
  users.users.ari.extraGroups = [ "input" ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest; # linuxPackages_hardened was removed in 26.05
  # Wake on Lan
  networking.interfaces.enp4s0.wakeOnLan.enable = true;
  networking.interfaces.lo.wakeOnLan.enable = true;
  # Extra Packages
  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
    libnvidia-container
    docker
    runc
  ];
  # Steam
  programs.steam = {
    enable = false;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
