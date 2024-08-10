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
    skyg.user = {
      enabled = mkEnableOption "";
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
      enableDevelopmentKit = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config =
    let
      hm = (import ../home-manager.nix {
        stateVersion = cfg.home-manager.version;
      });
    in
    mkIf cfg.user.enabled
      {
        programs.zsh.enable = true;
        home-manager.users.root = hm.makeRootUser { pkgs = pkgs; };
        home-manager.users.${cfg.user.name} = (hm.makeCommonUser cfg.user) { pkgs = pkgs; };
      };
}
