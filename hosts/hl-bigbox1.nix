{ user }:
{ pkgs, lib, config, unstable, ... }: {
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
  # Nvidia Settings
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.enable = true;
  hardware.graphics = { enable = true; };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.production;
  };
}
