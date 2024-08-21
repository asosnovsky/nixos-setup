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
    users.groups.shared-files = {
      gid = 6660;
      members = [
        config.skyg.user.name
      ];
    };
  };
}
