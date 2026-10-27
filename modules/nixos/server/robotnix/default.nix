# robotnix lives in its own repo (flake input `robotnix`). This adapter
# imports its host module and fills its defaults from skyg values.
# Hosts configure it under services.robotnix. See ABOUTME.md.
{ config, lib, robotnix, ... }:
let
  cfg = config.services.robotnix;
  apps = config.skyg.internalNetworkingMap.apps;
in
{
  imports = [ robotnix.nixosModules.default ];

  config = lib.mkIf cfg.enable {
    services.robotnix = {
      user = lib.mkDefault config.skyg.user.name;
      authorizedKeys = lib.mkDefault config.skyg.nixos.common.ssh-server.masterPubKeys;
      dnsUpstreams = lib.mkDefault [ config.skyg.internalNetworkingMap.appNetwork.gateway ];
      localDomains = lib.mkDefault [
        "app.internal"
        "lab.internal"
      ];
    };

    # A robot's address must not clash with an app from the network map.
    assertions = lib.mapAttrsToList
      (name: r:
        let
          clash = lib.attrNames (lib.filterAttrs (an: a: a.ip == r.address && an != name) apps);
        in
        {
          assertion = clash == [ ];
          message = "robotnix: ${name}'s address ${r.address} is already used by app(s): ${toString clash}.";
        })
      cfg.robots;
  };
}
