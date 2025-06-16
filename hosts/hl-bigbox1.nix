{ ... }:
{ pkgs, config, ... }:
{
  imports = [ ./hl-bigbox1.hardware-configuration.nix ];
  skyg = {
    user.enable = true;
    server.admin.enable = true;
    server.exporters.enable = true;
    server.timers = {
      jellyfin-backups = {
        OnCalendar = "daily";
        wantedBy = [
          "mnt-terra1-Data-apps.mount"
        ];
        script = ''
          set -eu
          ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/jellyfin /mnt/terra1/Data/apps/
        '';
      };
    };
    nixos = {
      desktop = {
        enable = true;
        gnome.enable = true;
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
        dockge = {
          enable = true;
          openFirewall = true;
          volumes = {
            stacks = {
              nfsServer = "terra1.lab.internal";
              share = "/mnt/Data/apps/bigbox/dockge/stacks";
            };
            data = {
              nfsServer = "terra1.lab.internal";
              share = "/mnt/Data/apps/bigbox/dockge/data";
            };
          };
        };
      };
    };
    networkDrives.enable = true;
  };
  services.displayManager.defaultSession = "gnome";
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
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
  services.xserver.displayManager.gdm.autoSuspend = false;
  services.xserver.displayManager.gdm.autoLogin.delay = 0;
  # Remote Desktop
  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "${pkgs.gnome-session}/bin/gnome-session";
  services.xrdp.openFirewall = true;
  # Sunshine
  services.sunshine = {
    enable = true;
    autoStart = true;
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
  boot.kernelPackages = pkgs.linuxPackages_hardened;
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
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
}
