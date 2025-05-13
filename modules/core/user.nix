{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg;
in
{
  options = {
    skyg.home-manager.version = mkOption {
      type = types.str;
    };
    skyg.home-manager.extraImports = mkOption {
      default = [ ];
    };
    skyg.user = {
      enable = mkEnableOption "";
      name = mkOption {
        type = types.str;
      };
      fullName = mkOption {
        type = types.str;
      };
      email = mkOption {
        type = types.str;
      };
      extraGitConfigs = mkOption {
        type = types.listOf (types.submodule {
          path = mkOption {
            type = types.str;
          };
        });
        default = [ ];
      };
    };
  };

  config =
    let
      hm = (import ../home {
        stateVersion = cfg.home-manager.version;
      });
    in
    mkIf cfg.user.enable
      {
        programs.zsh.enable = true;
        home-manager.users.root =
          (hm.makeRootUser { hostName = config.skyg.core.hostName; }) { pkgs = pkgs; };
        home-manager.users.${cfg.user.name} =
          ((hm.makeCommonUser cfg.user) { pkgs = pkgs; }) // {
            imports = cfg.home-manager.extraImports;
          };
      };
}
