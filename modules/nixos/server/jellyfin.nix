{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.jellyfin;
in
{
  options = {
    skyg.nixos.server.services.jellyfin = {
      enable = mkEnableOption
        "Enable AI Services";
    };
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      dataDir = "/mnt/apps/jellyfin/datadir";
      configDir = "/mnt/apps/jellyfin/configdir";
      openFirewall = true;
    };
    fileSystems."/mnt/apps/jellyfin" = {
      device = "terra1.lab.internal:/mnt/Data/apps/jellyfin";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };
    fileSystems."/family-videos" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/FamilyStorage/Video";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };
  };
}
