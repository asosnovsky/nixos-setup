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
  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
    cudaPackages.cudnn
  ];
  # Ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    host = "0.0.0.0";
    environmentVariables = {
      OLLAMA_LLM_LIBRARY = "cuda";
      LD_LIBRARY_PATH = "run/opengl-driver/lib";
      NVARCH = "x86_64";
      NV_CUDA_CUDART_VERSION = "11.3.1";
      NVIDIA_VISIBLE_DEVICES = "all";
    };
  };
  # Nvidia Settings
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = { enable = true; };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
