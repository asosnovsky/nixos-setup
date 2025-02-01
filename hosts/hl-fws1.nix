{ user }:
{ pkgs, lib, config, ... }:
let
  scriptsFolder = builtins.filterSource (p: t: true) ./scripts/fw1;
in
{
  imports = [ ./hl-fws1.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.admin.enable = true;
  skyg.networkDrives.options = [
    "x-systemd.automount"
    "auto"
  ];

  # firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;

  # Game Engine
  boot.kernelPackages = pkgs.linuxPackages; # (this is the default) some amdgpu issues on 6.10
  programs = {
    gamescope = {
      enable = true;
      capSysNice = true;
    };
    steam = {
      enable = true;
      gamescopeSession.enable = true;
      extest.enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };
  services.getty.autologinUser = "ari";
  environment = {
    systemPackages = with pkgs;[ mangohud ];
    loginShellInit = ''
      [[ "$(tty)" = "/dev/tty1" ]] && ${scriptsFolder}/gs.sh
    '';
  };
}

