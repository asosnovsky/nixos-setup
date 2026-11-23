{ config
, lib
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
    programs.bat = {
      enable = true;
      settings.theme = "gruvbox-dark";
    };
  };
}
