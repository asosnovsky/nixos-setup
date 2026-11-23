{ config
, lib
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
    programs.gnupg.agent = {
      enable = true;
      settings.default-cache-ttl = 1800;
    };
  };
}
