{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.user;
in
{
  options.skyg.user.createSystemUser = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to create the system user (separate from home-manager configuration)";
  };

  config = lib.mkIf (cfg.name != "" && cfg.createSystemUser) {
    users.users.root = {
      shell = pkgs.zsh;
    };
    users.users.${cfg.name} = {
      shell = pkgs.zsh;
      isNormalUser = true;
      description = cfg.fullName;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    };
  };
}
