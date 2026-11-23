{ config
, lib
, ...
}:

with lib;

let
  cfg = config.skyg;
in
{
  options = {
    skyg.user = {
      enable = mkEnableOption "the shell and CLI setup for the main user and root (see nixos/common/user-env/)";
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

  config = mkIf cfg.user.enable {
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
  };
}
