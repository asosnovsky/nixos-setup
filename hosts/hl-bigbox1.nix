{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-bigbox1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  virtualisation.docker.enableNvidia = true;
  hardware.nvidia-container-toolkit.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Containers
  virtualisation.oci-containers = {
    containers = {
      ollama = {
        autoStart = true;
        image = "ollama/ollama";
        extraOptions = [ "--gpus" "all" ];
        ports = [ "11434:11434" ];
        volumes = [ "ollama:/root/.ollama" ];
      };
      openwakeword = {
        autoStart = true;
        image = "rhasspy/wyoming-openwakeword";
        cmd = [ "--preload-model" "ok_nabu" ];
        ports = [ "10400:10400" ];
      };
    };
  };

  # Wyoming Service
  services.wyoming = {
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
	];
}
