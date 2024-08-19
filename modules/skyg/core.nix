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
    networking.hostName = cfg.hostName;
  };
}
