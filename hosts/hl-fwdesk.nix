{ ... }:
{ pkgs, ... }:
let
  ports = {
    tabby = 11029;
    ollama = 11434;
  };
  openPorts = [ ports.ollama ports.tabby ];
in
{
  imports = [ ./hl-fwdesk.hardware-configuration.nix ];
  # Skyg
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = 1;
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  skyg = {
    user.enable = true;
    nixos = {
      common.hardware = {
        sound.enable = true;
        pipewire.enable = true;
        amdgpu.enable = true;
      };
      desktop = {
	      stylix.enable = true;
        enable = true;
        cosmic.enable = true;
        tiler = {
          enable = true;
          niri.enable = true;
          hyprland.enable = false;
        };
      };
    };
    networkDrives = {
      enable = false;
      options = [
        "x-systemd.automount"
        "noauto"
      ];
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
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
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
      python313
      cargo
      rustc
      go
      pipx
      uv

      # development
      zed-editor-fhs
      nix-prefetch
    ]);
  services.usbmuxd.enable = true;
  # Phone
  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  # Ollama
  services.open-webui.enable = true;
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = ports.ollama;
    acceleration = "rocm";
  };
  # Tabby
  services.tabby = {
    enable = true;
    acceleration = "rocm";
    host = "0.0.0.0";
    port = ports.tabby;
  };
  environment.localBinInPath = true;
  programs.nh = {
    enable = true;
    flake = "/home/ari/nixos-setup";
    clean.enable = true;
  };
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
