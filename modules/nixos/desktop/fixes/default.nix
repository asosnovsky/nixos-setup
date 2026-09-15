{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.desktop.fixes.airpod-bluetooth;
in
{
  options = {
    skyg.nixos.desktop.fixes.airpod-bluetooth = {
      enabled = lib.mkEnableOption "AirPods Bluetooth mic via HFP (lower call quality)";
    };
  };

  config = lib.mkIf (cfg.enabled && config.skyg.nixos.desktop.enable) {
    # Switch AirPods to HFP when a mic is needed so the AirPods mic
    # shows as an input. Call audio is HFP (mSBC if supported), not A2DP.
    services.pipewire.wireplumber.extraConfig = {
      "51-airpods-bluetooth" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-msbc" = true;
          "bluez5.msbc-support" = true;
          "bluez5.hfphsp-backend" = "native";
          "bluez5.roles" = [
            "a2dp_sink"
            "a2dp_source"
            "hsp_hs"
            "hsp_ag"
            "hfp_hf"
            "hfp_ag"
          ];
        };
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = true;
        };
      };
    };
  };
}
