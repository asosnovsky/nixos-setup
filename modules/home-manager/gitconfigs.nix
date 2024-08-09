{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.home-manager.gitaliases;
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ./gitconfigs);
  gitconfigFiles = builtins.attrNames (builtins.readDir gitconfigs);

in
{
  options = {
    skyg.home-manager.gitaliases = {
      enable = mkEnableOption
        "Use my awesome git aliases";
    };
  };

  config = mkIf cfg.enable { };
}
