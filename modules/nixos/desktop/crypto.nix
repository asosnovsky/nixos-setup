{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop.crypto;
in
{
  options = {
    skyg.nixos.desktop.crypto = {
      enabled = mkEnableOption
        "Enable crypto wallets";
    };
  };
  config = mkIf cfg.enabled {
    environment.systemPackages = with pkgs; [
      trezor-suite
      trezord
      ledger-live-desktop
    ];
    # udev rules for crypto wallets
    services.udev.packages = with pkgs; [
      ledger-udev-rules
      trezor-udev-rules
    ];
    # trezor groups
    users.groups.trezord = { };
    users.groups.trezord.members = [ config.skyg.user.name ];
  };
}
