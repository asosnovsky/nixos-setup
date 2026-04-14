{ config
, lib
, pkgs
, ...
}:

with lib;

let
  cfg = config.skyg;
in
{
  options = {
    skyg.home-manager.version = mkOption {
      type = types.str;
      default = "24.11";
      description = "The home-manager state version";
    };
    skyg.home-manager.extraImports = mkOption {
      type = types.listOf types.anything;
      default = [ ];
      description = "Extra imports to add to the user's home-manager configuration";
    };
    skyg.user = {
      enable = mkEnableOption "home-manager configuration for the user";
      name = mkOption {
        type = types.str;
        default = "";
        description = "The username";
      };
      fullName = mkOption {
        type = types.str;
        default = "";
        description = "The user's full name";
      };
      email = mkOption {
        type = types.str;
        default = "";
        description = "The user's email address";
      };
      extraGitConfigs = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              path = mkOption {
                type = types.str;
              };
            };
          }
        );
        default = [ ];
        description = "Extra git configuration files to include";
      };
    };
  };

  config =
    let
      hm = (
        import ../home {
          stateVersion = cfg.home-manager.version;
        }
      );
    in
    mkIf cfg.user.enable {
      # Ensure user.name is set when enabling
      assertions = [
        {
          assertion = cfg.user.name != "";
          message = "skyg.user.name must be set when skyg.user.enable is true";
        }
        {
          assertion = cfg.user.fullName != "";
          message = "skyg.user.fullName must be set when skyg.user.enable is true";
        }
        {
          assertion = cfg.user.email != "";
          message = "skyg.user.email must be set when skyg.user.enable is true";
        }
      ];

      programs.zsh.enable = true;
      home-manager = {
        backupFileExtension = ".bak";
        useGlobalPkgs = true;
        useUserPackages = true;
        users.root = (hm.makeRootUser { hostName = config.skyg.core.hostName; }) {
          pkgs = pkgs;
        };
        users.${cfg.user.name} = ((hm.makeCommonUser cfg.user) { pkgs = pkgs; }) // {
          imports = cfg.home-manager.extraImports;
        };
      };
    };
}
