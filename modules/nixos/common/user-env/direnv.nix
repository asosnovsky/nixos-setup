{ config
, lib
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = false;
    };
  };
}
