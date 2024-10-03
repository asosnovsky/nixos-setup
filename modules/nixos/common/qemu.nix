{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.core.qemu;
in
{
  options = {
    skyg.core.qemu = {
      enable = lib.mkEnableOption
        "Enable qemu";
    };
  };
  config = lib.mkIf cfg.enable {
    environment = {
      systemPackages = with pkgs; [
        qemu
        quickemu
        spice-vdagent
        spice-autorandr
      ];
      services.spice-vdagentd.enable = true;
      services.spice-autorandr.enable = true;
    };
  };
}
