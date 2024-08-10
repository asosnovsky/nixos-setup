{ config, lib, pkgs, ... }:

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
    users.users.root.shell = pkgs.zsh;
    home-manager.users.root.programs.git.userEmail = "root@${cfg.hostName}";
    networking.hostName = cfg.hostName;
  };
}
