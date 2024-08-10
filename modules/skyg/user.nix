{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg;
  hm = (import ../home-manager.nix cfg.user);
in
{
  options = {
    skyg.home-manager.version = mkOption {
      type = types.str;
    };
    skyg.user = {
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

  config = {
    programs.zsh.enable = true;
    home-manager.users.root = hm.makeRootUser { pkgs = pkgs; };
    home-manager.users.${cfg.user.name} = hm.makeCommonUser { pkgs = pkgs; };
  };
}
