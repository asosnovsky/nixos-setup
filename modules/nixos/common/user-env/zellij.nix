{ config
, lib
, pkgs
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
    environment.systemPackages = [ pkgs.zellij ];

    skyg.configLinks.links.zellij = {
      source = "shared/zellij/config.kdl";
      target = ".config/zellij/config.kdl";
      root = true;
    };
  };
}
