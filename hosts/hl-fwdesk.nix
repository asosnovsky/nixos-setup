{ pkgs
, ...
}:
let
  ports = {
    tabby = 11029;
    ollama = 11434;
    piper = 10200;
    fastWhisper = 10300;
    wyoming = 10400;
    comfyui = 8188;
  };
  openPorts = [
  	ports.ollama
    ports.tabby
    ports.fastWhisper
    ports.piper
    ports.wyoming
    ports.comfyui
  ];
in
{
  imports = [ ./hl-fwdesk.hardware-configuration.nix ];
  # Skyg
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = 1;
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  skyg = {
    user.enable = true;
    core.qemu.enable = true;
    nixos = {
      common.ssh-server.enable = true;
      common.hardware = {
        sound.enable = true;
        pipewire.enable = true;
        amdgpu.enable = true;
      };
      desktop = {
        stylix.enable = true;
        enable = true;
        tiler = {
          enable = true;
          niri.enable = true;
        };
      };
    };
    networkDrives = {
      enable = true;
      # options = [
      #   "x-systemd.automount"
      #   "noauto"
      # ];
    };
  };
  users.users.ari.extraGroups = [
    "input"
    "disk"
    "wheel"
    "tty"
    "dialout"
    "plugdev"
    "uucp"
    "render"
    "video"
    "docker"
  ];
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Tailscale
  services.tailscale.enable = true;
  # Desktop Env
  services.displayManager.gdm.enable = true;
  services.displayManager.gdm.wayland = true;
  services.displayManager.defaultSession = "niri";
  # Firmware updater
  services.fwupd.enable = true;
  # Bluetooth
  hardware.bluetooth.settings.General = { ControllerMode = "bredr"; };
  hardware.bluetooth.enable = true;
  # Bootloader.
  environment.systemPackages =
    (with pkgs; [
      # languages
      # cargo
      rustc
      go
      pipx
      uv

      # development
      zed-editor-fhs
      nix-prefetch

      # Steam
      mangohud

      # LLM Stuff
      ollama-rocm
      # stable-diffusion-cpp-rocm
      lmstudio
    ]);
  services.usbmuxd.enable = true;
  # Steam
  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
  boot.kernelPackages = pkgs.linuxPackages; # (this is the default) some amdgpu issues on 6.10
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
  };
  hardware.xone.enable = true; # support for the xbox controller USB dongle
  # Ollama
  services.open-webui.enable = true;
  users.users.ollama = {
    enable = true;
    home = "/var/lib/ollama";
    extraGroups = [
      "render"
      "video"
    ];
  };
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = ports.ollama;
    acceleration = "vulkan";
    user = "ollama";
    home = "/var/lib/ollama";
    rocmOverrideGfx = "gfx1151";
    # rocmOverrideGfx = "11.5.1";

    environmentVariables = {
      # Stability fix — SDMA is buggy on Strix Halo unified memory
      HSA_ENABLE_SDMA       = "0";
      # Flash attention for better performance
      OLLAMA_FLASH_ATTENTION = "1";
      # Keep models loaded
      OLLAMA_KEEP_ALIVE     = "24h";
    };
  };
  hardware.graphics.enable = true;
  hardware.enableAllFirmware = true;
  hardware.amdgpu = {
    opencl.enable = true;
  };
  environment.localBinInPath = true;
  programs.nh = {
    enable = true;
    flake = "/home/ari/nixos-setup";
    clean.enable = true;
  };
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
  services.wyoming = {
    openwakeword = {
      enable = true;
      uri = "tcp://0.0.0.0:${toString ports.wyoming}";
    };
    piper.servers.peta = {
      enable = true;
      uri = "tcp://0.0.0.0:${toString ports.piper}";
      voice = "en_US-danny-low";
      streaming = true;
    };
    faster-whisper.servers.todd = {
	   	enable = true;
			uri = "tcp://0.0.0.0:${toString ports.fastWhisper}";
			model = "tiny.en";
			language = "en";
			device = "auto";
    };
  };
  virtualisation.docker = {
    enable = true;
    daemon.settings = {
      # Allows containers to access /dev/kfd and /dev/dri
      "default-runtime" = "runc";
    };
  };
}
