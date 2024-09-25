{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.core.substituters;
  skygUser = config.skyg.user;
in
{
  options = {
    skyg.core.substituters = {
      urls = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
      keys = mkOption {
        type = types.listOf types.str;
        default = [ ];
      };
    };
  };

  config = {
    nix.settings.substituters = [
      "https://cache.nixos.org"
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
      "https://hyprland.cachix.org"
    ] ++ cfg.urls;
    nix.settings.trusted-substituters = [
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
    ] ++ cfg.urls;
    nix.settings.trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ] ++ cfg.keys;
    nix.settings.trusted-users = [ "root" skygUser.name ];
  };
}
