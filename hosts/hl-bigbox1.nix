{ ... }:
{ pkgs, ... }:
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
      common.ssh-server.enable = true;
      common.containers.openMetricsPort = true;
      common.hardware = {
        nvidia.enable = true;
        amdgpu.enable = true;
      };
      server.services = {
        ai.enable = true;
        jellyfin.enable = false;
      };
    };
    networkDrives.enable = true;
  };
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
  networking.interfaces.tailscale0.wakeOnLan.enable = true;
  # Suspend
  services.autosuspend.enable = false;
  services.xserver.displayManager.gdm.autoSuspend = false;

  environment.systemPackages = with pkgs; [
    # steam-tui
    # steam-run
    # steamPackages.steamcmd
    ollama
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
  ];
}
