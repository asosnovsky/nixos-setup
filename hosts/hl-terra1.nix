{ user }:
{ pkgs, lib, config, ... }:
let
  fanCfgFile = pkgs.writeText "/etc/fancontrol" ''INTERVAL=10
DEVPATH=hwmon0=devices/platform/coretemp.0 hwmon1=devices/platform/it87.2592
DEVNAME=hwmon0=coretemp hwmon1=it8613
FCTEMPS=hwmon1/pwm3=hwmon0/temp1_input
FCFANS= hwmon1/pwm3=hwmon1/fan3_input
MINTEMP=hwmon1/pwm3=20
MAXTEMP=hwmon1/pwm3=60
MINSTART=hwmon1/pwm3=52
MINSTOP=hwmon1/pwm3=12'';
in
{
  imports = [ ./hl-terra1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  homelab.hardware.fancontrol = {
    enable = true;
    configName = fanCfgFile;
  };
  homelab.nix.remote-builder.enable = true;

}

