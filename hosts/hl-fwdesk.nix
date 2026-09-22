{ pkgs
, unstablePkgs
, myPkgs
, my-nixpkgs
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
    ds4 = 8000;
    colibri = 8001;
    hermes = 8642;
    hermesDashboard = 9119;
    hermesCache = 5001;
    vnc = 5930;
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
    ports.vnc
  ];
in
{
  imports = [
    ./hl-fwdesk.hardware-configuration.nix
    # DwarfStar ds4 systemd module (services.ds4) from asosnovsky/nixpkgs fork (branch ds4-init).
    "${my-nixpkgs}/nixos/modules/services/misc/ds4.nix"
  ];
  # Skyg
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  skyg = {
    user.enable = true;
    core.qemu.enable = true;
    nixos = {
      common.ssh-server.enable = true;
      common.cachePush.enable = true;
      common.hardware = {
        pipewire.enable = true;
        amdgpu.enable = true;
      };
      desktop = {
        enable = true;
        tiler = {
          enable = true;
          noctalia = {
            enable = true;
          };
          hyprland = {
            enable = true;
            tools.enable = true;
            configLink = {
              enable = true;
              mountAsSource = true;
            };
          };
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
      server.services.colibri = {
        enable = false;
        package = pkgs.colibri-rocm;
        model = "/var/lib/colibri/glm52_i4";
        host = "0.0.0.0";
        port = ports.colibri;
        autoStart = false;
        openFirewall = true;
      };
    };
    networkDrives = {
      enable = true;
    };
  };
  # DwarfStar (antirez/ds4) inference server — services.ds4 module from
  # asosnovsky/nixpkgs (ds4-init fork branch); package is the fork's ROCm
  # build for Strix Halo (gfx1151), see flake.nix:
  services.ds4 = {
    enable = true;
    # Strix Halo == gfx1151. Pin explicitly: the fork package's auto-detected
    package = (myPkgs.ds4-rocm.override { rocmArch = "gfx1151"; });

    user = "ari";
    group = "users";
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
    autoStart = false;
    # Not a services.ds4 option in the fork module yet; pass the flag through.
    extraArgs = [ "--kv-cache-reject-different-quant" ];
    extraServiceConfig = {
      TimeoutStopSec = "300";
    };
  };
  users.users.ari.extraGroups = [
    "input"
    "wheel"
    "tty"
    "dialout"
    "uucp"
    "render"
    "video"
    "docker"
  ];
  # Boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # QEMU emulation for building aarch64 (e.g. hl-pi1) as a remote build machine
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  # Tailscale
  services.tailscale.enable = true;
  # Desktop Env - DankGreeter
  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/ari";
  };
  # Boot straight into the Hyprland desktop as ari, no password (Steam Big Picture auto-starts)
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.autoLogin = {
    enable = true;
    user = "ari";
  };
  # Firmware updater
  services.fwupd.enable = true;
  # Bluetooth
  skyg.nixos.common.hardware.bluetooth.enable = true;
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
      herdr

      # Steam
      mangohud

      # LLM Stuff
      unstablePkgs.ollama-rocm
      unstablePkgs.grok-build
      # stable-diffusion-cpp-rocm
      lmstudio
      # Hermes gateway - Signal bridge (used to link the device + run the daemon)
      signal-cli

      # bluetooth
      blueman

    ])
    ++ [ myPkgs.ds4-rocm ];
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
    package = pkgs.ollama-rocm;
    user = "ollama";
    home = "/var/lib/ollama";
    environmentVariables = {
      HSA_ENABLE_SDMA = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
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

  # Hermes Agent — hardened, self-managing NixOS VM
  services.hermenix = {
    enable = true;
    disk.baseDir = "/var/lib/hermes-vm";
    disk.stateSize = "60G";
    network.externalInterface = "enp191s0";
    vcpu = 3;
    mem = 5000;
    hermesHome = "/var/lib/hermes/.hermes";
    hostCache.port = ports.hermesCache;
    hostAccess = [
      { port = ports.ollama; }
      { port = ports.ds4; }
    ];
    lanAccess = [
      { address = "10.0.12.1"; port = 80; } # Home Assistant
      # *.app.internal apps on the macvlan lab subnet (drawdb, audiobooks, ...)
      { address = "10.0.101.0/24"; port = 80; }
      { address = "10.0.101.0/24"; port = 443; }
      # Buzz relay — its own IP, not the whole subnet
      { address = "10.0.101.3"; port = 3000; } # relay
      { address = "10.0.101.3"; port = 8080; } # health
      { address = "10.0.101.3"; port = 9102; } # metrics
      # Gitea
      { address = "10.0.10.6"; port = 3000; }
    ];
    publish = [
      { hostPort = ports.hermes; guestPort = 8642; }
      { hostPort = ports.hermesDashboard; guestPort = 9119; }
    ];
  };
  hardware.enableAllFirmware = true;
  hardware.amdgpu = {
    opencl.enable = true;
  };
  skyg.nixos.common.nh.flake = "/home/ari/nixos-setup";
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
      "default-runtime" = "runc";
    };
  };
  services.flatpak.enable = true;
}
