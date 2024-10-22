{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.server.arrs;
  dbPort = 5432;
  rootDataDir = "/var/lib/arrs";
  makeConfig = { port, name, uid, gid }: {
    enable = lib.mkEnableOption "Enable ${name}";

    package = lib.mkPackageOption pkgs name { };
    openFirewall = lib.mkEnableOption "Open port for ${name}";

    user = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    uid = lib.mkOption {
      type = lib.types.number;
      default = uid;
    };
    gid = lib.mkOption {
      type = lib.types.number;
      default = gid;
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = port;
      description = "Port for ${name}";
    };
  };
in
{
  imports = [
    ./db.nix
    ./prowlarr.nix
  ];
  options = {
    skyg.server.arrs = {
      enable = lib.mkEnableOption
        "Enable Arr Stack Store";
      openFirewall = lib.mkEnableOption
        "Open Firewall ports for services";
      rootDataDir = lib.mkOption {
        type = lib.types.str;
        default = rootDataDir;
      };
    };
    skyg.server.arrs.database = {
      port = lib.mkOption {
        type = lib.types.int;
        default = dbPort;
      };
    };
    skyg.server.arrs.prowlarr = makeConfig {
      name = "prowlarr";
      port = 9096;
      uid = 9000;
      gid = 9000;
    };
    skyg.server.arrs.sonarr = makeConfig {
      name = "sonarr";
      port = 8989;
      uid = 9001;
      gid = 9001;
    };
    skyg.server.arrs.radarr = makeConfig {
      name = "radarr";
      port = 7878;
      uid = 9002;
      gid = 9002;
    };
  };
  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [

    ];
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [

    ];
  };
}
