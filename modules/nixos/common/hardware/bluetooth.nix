{ lib
, config
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.bluetooth;
in
{
  options.skyg.nixos.common.hardware.bluetooth = with lib; {
    enable = mkEnableOption "bluetooth, BR/EDR only (BLE disabled)";
  };

  config = lib.mkIf cfg.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings.General.ControllerMode = "bredr";
  };
}
