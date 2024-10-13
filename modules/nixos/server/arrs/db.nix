{ config, lib, ... }:
let
  cfg = config.skyg.server.arrs;
  ifAdd = cond: add: if cond then [ add ] else [ ];
in
{
  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      settings.port = cfg.database.port;
      dataDir = cfg.database.dataDir;
      ensureDatabases =
        (ifAdd cfg.prowlarr cfg.prowlarr.user) ++
        (ifAdd cfg.radarr cfg.radarr.user) ++
        (ifAdd cfg.sonarr cfg.sonarr.user)
      ;
      ensureUsers =
        (ifAdd cfg.prowlarr cfg.prowlarr.user) ++
        (ifAdd cfg.radarr cfg.radarr.user) ++
        (ifAdd cfg.sonarr cfg.sonarr.user)
      ;
    };
  };
}
