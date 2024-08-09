{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.core;
in
{
  options = {
    skyg.core = {
      hostName = mkOption {
        description = "Machine Hostname";
        type = types.str;
      };
    };
  };

  config = {
    home-manager.users.root.programs.git.userEmail = "root@${cfg.hostName}";
    networking.hostName = cfg.hostName;
  };
}
