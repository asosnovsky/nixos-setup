{ user }:
{ pkgs, lib, config, ... }:
{
  imports = [ ./hl-bigbox1.hardware-configuration.nix ];
  skyg.user.enabled = true;
  skyg.nixos.common.ssh-server.enabled = true;
  skyg.nixos.server.services.ai.enable = true;
  skyg.nixos.server.services.jellyfin.enable = true;
  skyg.nixos.desktop.kde.enabled = true;
  skyg.nixos.desktop.enabled = false;
	skyg.server.admin.enable = true;
	users.users.ari.extraGroups = [ "input" ];
	# firmware updater
  services.fwupd.enable = true;
  virtualisation.docker.enableNvidia = true;
  hardware.nvidia-container-toolkit.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Nvidia Settings
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.enable = true;
  #services.openssh.settings.X11Forwarding = true;
  #services.xserver.displayManager.gdm.autoLogin.delay = 0;
  #services.displayManager.autoLogin = {
  #  enable = true;
  #  user = config.skyg.user.name;
  #};
  hardware.graphics.enable32Bit = true;
  hardware.graphics.enable = true;
  #hardware.opengl.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # Steam Settings
  users.users.steam = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = "Steam User";
    extraGroups = [ "wheel" "input" ];
  };
  # Sunshine Service
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true;
    openFirewall = true;
  };
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  environment.systemPackages = with pkgs; [
    steam-tui
    steam-run
    steamPackages.steamcmd
    ollama
pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];
}
