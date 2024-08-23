{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.jellyfin;
  user = "jellyfin";
  group = "jellyfin";
in
{
  options = {
    skyg.nixos.server.services.jellyfin = {
      enable = mkEnableOption
        "Enable Jellyfish";
    };
  };

  config = mkIf cfg.enable {
    users.users.${user} = {
      uid = 7777;
      isSystemUser = true;
    };
    users.groups.${group} = {
      gid = 7777;
      members = [
        user
        config.skyg.user.name
      ];
    };
    users.groups.www-data.members = [
      user
    ];
    services.jellyfin = {
      inherit user group;
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
