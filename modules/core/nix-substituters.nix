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
      "https://cuda-maintainers.cachix.org"
    ] ++ cfg.urls;
    nix.settings.trusted-substituters = [
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ] ++ cfg.urls;
    nix.settings.trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ] ++ cfg.keys;
    nix.settings.trusted-users = [ "root" skygUser.name ];
  };
}
