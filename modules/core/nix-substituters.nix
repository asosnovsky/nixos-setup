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
      "http://minipc1.lab.internal:5000"
      "https://cache.nixos.org"
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "https://cosmic.cachix.org/"
      "https://ai.cachix.org"
    ] ++ cfg.urls;
    nix.settings.trusted-substituters = [
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
      "https://cuda-maintainers.cachix.org"
      "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
    ] ++ cfg.urls;
    nix.settings.trusted-public-keys = [
      "minipc1.lab.internal:buUlsyg+xRqkUk0MWACmIyRUtHIOPQQzg7nc4qZCc4E="
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    ] ++ cfg.keys;
    nix.settings.trusted-users = [ "root" skygUser.name ];
    nix.extraOptions = ''
      # Ensure we can still build when missing-server is not accessible
      fallback = true
    '';
  };
}
