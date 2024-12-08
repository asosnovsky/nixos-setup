{ ... }:
{ pkgs, config, ... }:
{
  imports = [ ./hl-bigbox1.hardware-configuration.nix ];
  skyg = {
    user.enable = true;
    server.admin.enable = true;
    server.exporters.enable = true;
    nixos = {
      common.ssh-server.enable = true;
      common.containers.openMetricsPort = true;
      server.services = {
        ai.enable = true;
        jellyfin.enable = false;
      };
    };
  };
  users.users.ari.extraGroups = [ "input" ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Wake on Lan
  networking.interfaces.enp4s0.wakeOnLan.enable = true;
  networking.interfaces.lo.wakeOnLan.enable = true;
  networking.interfaces.tailscale0.wakeOnLan.enable = true;
  # Suspend
  services.autosuspend.enable = false;
  services.xserver.displayManager.gdm.autoSuspend = false;
  # Nvidia Settings
  # hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker.enableNvidia = true;
  hardware.graphics.enable32Bit = true;
  hardware.graphics.enable = true;
  hardware.nvidia = {
    # datacenter.enable = true;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
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
