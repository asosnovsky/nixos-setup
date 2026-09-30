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

      aliases = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [ "buzz.home.sosnovsky.ca" ];
        description = "Optional public/alternate DNS names for the app.";
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

    appNetwork = lib.mkOption {
      default = { };
      description = ''
        The lab network the apps live on. Consumed as the defaults for the
        ipvlan/macvlan container networks (skyg.nixos.common.containers.networks).
      '';
      type = lib.types.submodule {
        options = {
          subnet = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.0/16";
            description = "IPv4 subnet (--subnet).";
          };

          gateway = lib.mkOption {
            type = lib.types.str;
            default = "10.0.0.1";
            description = "IPv4 gateway (--gateway).";
          };

          ipRange = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "IPv4 range for dynamic address allocation (--ip-range).";
          };
        };
      };
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
      appNetwork = {
        subnet = "10.0.0.0/16";
        gateway = "10.0.0.1";
        ipRange = "10.0.101.16/28";
      };
      apps = {
        drawdb = { ip = "10.0.101.2"; };
        buzz = { ip = "10.0.101.3"; aliases = [ "buzz.home.sosnovsky.ca" ]; };
        audiobooks = { ip = "10.0.101.4"; };
        gitea = { ip = "10.0.101.8"; };
        nitw-gc = { ip = "10.0.101.9"; };
        jellyfin = { ip = "10.0.101.5"; };
        nvr = { ip = "10.0.101.6"; };
        portainer = { ip = "10.0.101.241"; };
        caddy = {
          ip = "10.0.101.7";
          aliases = [
            "nvr.home.sosnovsky.ca"
            "jellyfin.home.sosnovsky.ca"
            "portainer.home.sosnovsky.ca"
          ];
        };
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
