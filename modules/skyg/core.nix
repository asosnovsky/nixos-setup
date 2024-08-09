{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.core;
in
{
  options = {
    skyg.core = {
      hostname = mkOption {
        description = "Machine Hostname";
        type = types.str;
      };
    };
  };

  config = {
    home-manager.users.root.programs.git.userName = "root@${cfg.hostName}";
    networking.hostName = cfg.hostName;
  };
}
