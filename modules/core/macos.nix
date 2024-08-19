{ config, lib, ... }:

with lib;

let
  skygUser = config.skyg.user;
in
{
  options = {
    skyg.user.macos = {
      enableOverride = mkEnableOption "";
    };
  };

  config = mkIf skygUser.macos.enableOverride {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.${skygUser.name} = {
      home = {
        sessionVariables = { "DOCKER_DEFAULT_PLATFORM" = "linux/amd64"; };
      };
    };
  };
}
