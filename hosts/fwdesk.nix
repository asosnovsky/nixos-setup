{ ... }:
{ pkgs, ... }:
{
  imports = [ ./fwdesk.hardware-configuration.nix ];
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
        enable = true;
        tiler = {
          enable = true;
          niri.enable = true;
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
  # Tailscale
  services.tailscale.enable = true;
  # Desktop Env
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.displayManager.defaultSession = "niri";
  # Network
  networking.nameservers = [ "9.9.9.9" "1.1.1.1" ];
  services.resolved = {
    enable = true;
    dnssec = "true";
    fallbackDns = [ "9.9.9.9" "1.1.1.1" ];
    dnsovertls = "true";
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
      python312
      python313
      cargo
      rustc
      go
      pipx
      uv

      # development
      vscode
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
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    acceleration = "rocm";
    rocmOverrideGfx = "11.0.2";
  };
  # # Brother Printer
  environment.localBinInPath = true;
  programs.nh = {
    enable = true;
    flake = "/home/ari/nixos-setup";
    clean.enable = true;
  };
}
