{ config, lib, ... }:
let
  cfg = config.skyg.nixos.desktop.fixes.fingerprint-autosuspend;
in
{
  options = {
    skyg.nixos.desktop.fixes.fingerprint-autosuspend = {
      enabled = lib.mkEnableOption "Keep the Goodix MOC fingerprint reader out of USB autosuspend";
    };
  };

  config = lib.mkIf (cfg.enabled && config.skyg.nixos.desktop.enable) {
    # Framework Goodix MOC fingerprint reader (27c6:609c) resets whenever it is
    # probed while in USB autosuspend ("usb 1-4: reset full-speed USB device"),
    # and fprintd intermittently fails with "Cannot run while suspended".
    # Keep it powered so it responds reliably and stops the reset churn.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="27c6", ATTRS{idProduct}=="609c", ATTR{power/control}="on", ATTR{power/autosuspend_delay_ms}="-1"
    '';
  };
}
