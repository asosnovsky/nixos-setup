{ config, lib, ... }:
with lib;
let cfg = config.skyg.homelab.udevrules.coraltpu;
in {
  options = {
    skyg.homelab.udevrules.coraltpu = {
      enable = mkEnableOption
        "Enable Coral TPU Udev rules";
      symlinkName = mkOption {
        description = "The special symlink to give to the coral tpu";
        type = types.str;
        default = "coral1";
      };
    };
  };
  config = mkIf cfg.enable {
    services.udev.extraRules = ''
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", MODE="0664", TAG+="uaccess", SYMLINK+="${cfg.symlinkName}"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", MODE="0664", TAG+="uaccess", SYMLINK+="${cfg.symlinkName}"
    '';
  };
}
