{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop.crypto;
in
{
  options = {
    skyg.nixos.desktop.crypto = {
      enable = mkEnableOption
        "Enable crypto wallets";
    };
  };
  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      trezor-suite
      trezord
      ledger-live-desktop
      sparrow
    ];
    # udev rules for crypto wallets
    services.udev.packages = with pkgs; [
      ledger-udev-rules
      trezor-udev-rules
    ];
    services.udev.extraRules = ''
      ATTRS{idProduct}=="55d4", ATTRS{idVendor}=="1a86", SUBSYSTEM=="usb", TEST=="power/control", ATTR{power/control}="on"
      KERNEL=="ttyACM*", SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d4", MODE="0660", GROUP="dialout", SYMLINK+="jade%n"
    '';
    # trezor groups
    users.groups.trezord = { };
    users.groups.trezord.members = [ config.skyg.user.name ];
    # Ensure user is in dialout, uucp groups for serial access
    users.users.${config.skyg.user.name}.extraGroups = [
      "dialout"
      "uucp"
      "trezord"
    ];
  };
}
