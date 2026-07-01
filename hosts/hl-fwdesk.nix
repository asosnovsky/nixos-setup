{ pkgs
, config
, skygUtils
, lib
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
    libretranslate = 5000;
    signal = 8080;
    ds4 = 8000;
    hermes = 8642;
    hermesDashboard = 9119;
  };
  openPorts = [
    ports.ollama
    ports.tabby
    ports.fastWhisper
    ports.piper
    ports.wyoming
    ports.comfyui
    ports.libretranslate
    ports.ds4
    ports.hermes
    ports.hermesDashboard
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
        enable = true;
        tiler = {
          enable = true;
          niri.enable = true;
        };
      };
      server.services.comfyui = {
        enable = true;
        mode = "rocm";
        port = ports.comfyui;
        rocm = {
          dataDir = "/data/comfyui";
        };
      };
      server.services.ds4 = {
        enable = true;
        package = pkgs.ds4-rocm;
        model = "/var/lib/ds4/ds4flash.gguf";
        host = "0.0.0.0";
        port = ports.ds4;
        ctx = 100000;
        kvDiskDir = "/var/lib/ds4/kv";
        kvDiskSpaceMb = 8192;
        cors = true;
        environment = {
          HSA_ENABLE_SDMA = "0";
        };
        openFirewall = true;
      };
    };
    networkDrives = {
      enable = true;
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
  # Desktop Env - DankGreeter
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/ari";
  };
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
      # DwarfStar (antirez/ds4) — ROCm build for Strix Halo (gfx1151).
      ds4-rocm

      # Hermes gateway - Signal bridge (used to link the device + run the daemon)
      signal-cli
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
  # Strix Halo GTT memory tuning so the full 128 GB unified memory is GPU-visible
  # (required by ds4-rocm / large models per upstream STRIXHALO.md).
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=126976"
    "ttm.pages_limit=32505856"
    "ttm.page_pool_size=32505856"
  ];
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
    package = pkgs.ollama-vulkan;
    user = "ollama";
    home = "/var/lib/ollama";


    environmentVariables = {
      # Stability fix — SDMA is buggy on Strix Halo unified memory
      HSA_ENABLE_SDMA = "0";
      # Flash attention for better performance
      OLLAMA_FLASH_ATTENTION = "1";
      # Keep models loaded
      OLLAMA_KEEP_ALIVE = "24h";
    };
  };
  # Libretranslate
  services.libretranslate = {
    enable = true;
    host = "0.0.0.0";
    port = ports.libretranslate;
    threads = 10;
  };
  systemd.services.libretranslate.environment.ARGOS_DEVICE_TYPE = "cpu";

  # Hermes Agent gateway (Docker container)
  age.secrets.hermes-env.file = ../secrets/hermes-env.age;
  skyg.nixos.common.container-services.hermes-agent = {
    timeoutStopSec = 210;
    services.hermes = {
      image = "nousresearch/hermes-agent";
      command = [ "gateway" "run" ];
      ports = [
        "${toString ports.hermes}:8642"
        "${toString ports.hermesDashboard}:9119"
      ];
      volumes = [
        "/var/lib/hermes:/opt/data"
      ];
      environmentFiles = [ config.age.secrets.hermes-env.path ];
      environment = {
        PUID = "1000";
        PGID = "100";
      };
      extraConfig = {
        shm_size = "1g";
        extra_hosts = [ "host.docker.internal:host-gateway" ];
      };
    };
  };
  # Signal CLI
  skyg.nixos.server.services.signal-cli = {
    enable = false;
    host = "0.0.0.0";
    port = ports.signal;
    environmentFile = config.age.secrets.hermes-env.path;
  };

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
  services.flatpak.packages = [
    "org.chromium.Chromium"
  ];
}
