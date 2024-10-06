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
        win-spice
        spice
        spice-vdagent
        spice-autorandr
        virt-viewer
      ];
    };
    services.spice-vdagentd.enable = true;
    services.spice-autorandr.enable = true;
    services.spice-webdavd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
