{ pkgs, unstablePkgs, myPkgs, my-nixpkgs, ... }:
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
    ./packages.nix
    ./services
    ./hardware-configuration
    ./hardware.nix
    ./systemd.nix
    ./networking.nix
    "${my-nixpkgs}/nixos/modules/services/misc/ds4.nix"
  ];

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
          noctalia.enable = true;
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
        rocm.dataDir = "/data/comfyui";
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
    networkDrives.enable = true;
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

  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/ari";
  };
  services.displayManager.defaultSession = "hyprland";
  services.displayManager.autoLogin = {
    enable = true;
    user = "ari";
  };

  services.fwupd.enable = true;
  skyg.nixos.common.hardware.bluetooth.enable = true;

  services.usbmuxd.enable = true;

  virtualisation.docker = {
    enable = true;
    daemon.settings."default-runtime" = "runc";
  };
  services.flatpak.enable = true;

  skyg.nixos.common.nh.flake = "/home/ari/nixos-setup";
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
