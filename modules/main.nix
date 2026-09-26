{ user
, systemStateVersion
, hostName
, rootDir
, configsDir
, ...
}:
{ lib, config, ... }:
let
  # Global internal app registry: one place to declare each app's LAN IP and
  # optional public alias. Service files read these instead of hardcoding, and
  # the flake renders it into the router's DNS records.
  internalNetworkingMap = config.skyg.internalNetworkingMap;

  appType = lib.types.submodule ({ name, ... }: {
    options = {
      ip = lib.mkOption {
        type = lib.types.str;
        example = "10.0.101.3";
        description = "LAN IPv4 address of the app.";
      };

      aliasDns = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "buzz.home.sosnovsky.ca";
        description = "Optional public/alternate DNS name for the app.";
      };

      effectiveDns = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        description = ''
          Read-only: the app's internal DNS name, computed as
          "<app-name>" + skyg.internalNetworkingMap.rootDns.
        '';
      };
    };

    config.effectiveDns = "${name}${internalNetworkingMap.rootDns}";
  });
in
{
  imports = [
    ./core
    ./nixos
    ./network-drives.nix
  ];

  options.skyg.internalNetworkingMap = {
    rootDns = lib.mkOption {
      type = lib.types.str;
      default = ".app.internal";
      description = "Suffix appended to each app name to form its internal DNS name.";
    };

    subnet = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "10.0.101.0/24";
      description = "LAN subnet the apps live on (informational).";
    };

    apps = lib.mkOption {
      type = lib.types.attrsOf appType;
      default = { };
      description = ''
        Internal apps, keyed by app name. Each app's internal DNS name is
        "<name>" + rootDns, and the flake renders every app into the router's
        DNS records.
      '';
    };
  };

  config = {
    # Global internal app registry.
    skyg.internalNetworkingMap = {
      rootDns = ".app.internal";
      subnet = "10.0.101.0/24";
      apps = {
        audiobooks = { ip = "10.0.101.4"; };
        buzz = { ip = "10.0.101.3"; aliasDns = "buzz.home.sosnovsky.ca"; };
        drawdb = { ip = "10.0.101.2"; };
        portainer = { ip = "10.0.101.241"; };
      };
    };

    # Share defaults - using mkDefault so they can be overridden per-host
    skyg.user = {
      name = lib.mkDefault user.name;
      fullName = lib.mkDefault user.fullName;
      email = lib.mkDefault user.email;
    };
    skyg.rootDir = rootDir;
    skyg.configsDir = configsDir;
    skyg.core.hostName = hostName;
    skyg.home-manager.version = lib.mkDefault "26.05";
    system.stateVersion = systemStateVersion;
  };
}
