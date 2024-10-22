{ config, lib, ... }:
let
  cfg = config.skyg.server.arrs;
  ifAdd = cond: add: if cond then [ add ] else [ ];
  mkEnsureUser = name: {
    inherit name;
    ensureDBOwnership = true;
    ensureClauses.login = true;
    ensureClauses.createdb = true;
  };
in
{
  config = lib.mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      settings.port = cfg.database.port;
      dataDir = "${cfg.rootDataDir}/db";
      ensureDatabases =
        (ifAdd cfg.prowlarr.enable cfg.prowlarr.user) ++
        (ifAdd cfg.radarr.enable cfg.radarr.user) ++
        (ifAdd cfg.sonarr.enable cfg.sonarr.user)
      ;
      ensureUsers =
        (ifAdd cfg.prowlarr.enable (mkEnsureUser cfg.prowlarr.user)) ++
        (ifAdd cfg.radarr.enable (mkEnsureUser cfg.radarr.user)) ++
        (ifAdd cfg.sonarr.enable (mkEnsureUser cfg.sonarr.user))
      ;
    };
  };
}
