{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-bigbox1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
  };
  services.wyoming = {
    openwakeword.enable = true;
    faster-whisper.servers.main-eng = {
      enable = true;
      device = "cpu";
      model = "medium.en";
      language = "en";
      uri = "tcp://0.0.0.0:10300";
    };
    piper.servers.pier = {
      enable = true;
      uri = "tcp://0.0.0.0:10200";
      voice = "en_GB-alan-medium";
    };
  };
  # Nvidia Settings
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
}
