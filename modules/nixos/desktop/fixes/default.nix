{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.desktop.fixes.airpod-bluetooth;
in
{
  options = {
    skyg.nixos.desktop.fixes.airpod-bluetooth = {
      enabled = lib.mkEnableOption "Fix robotic/distorted audio with AirPods over Bluetooth";
    };
  };

  config = lib.mkIf (cfg.enabled && config.skyg.nixos.desktop.enable) {
    # Fix robotic/distorted audio with AirPods over Bluetooth.
    # WirePlumber 0.5 (nixpkgs 26.05+) auto-switches BT devices from A2DP to
    # HFP whenever any app opens a mic stream (Chromium, Slack, etc.), which
    # degrades both speaker and mic quality to 8 kHz CVSD/mSBC and causes the
    # robotic sound. Disabling auto-switch keeps AirPods in A2DP permanently;
    # meeting apps fall back to the laptop's built-in mic for input.
    services.pipewire.wireplumber.extraConfig = {
      "51-airpods-bluetooth" = {
        "monitor.bluez.properties" = {
          "bluez5.msbc-support" = false;
          "bluez5.hfphsp-backend" = "native";
        };
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };
    };
  };
}
