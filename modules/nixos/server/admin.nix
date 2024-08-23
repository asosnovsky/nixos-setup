{ config, lib, ... }:
with lib;
let cfg = config.skyg.server.admin;
in {
  options = {
    skyg.server.admin = {
      enable = mkEnableOption
        "Enable special linux user & groups";
    };
  };
  config = mkIf cfg.enable {
    users.groups.www-data = {
      gid = 33;
      members = [
        config.skyg.user.name
      ];
    };
  };
}
