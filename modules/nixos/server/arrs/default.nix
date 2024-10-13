{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.server.arrs;
  dbPort = 5432;
  makeConfig = { port, name, uid, gid }: {
    enable = lib.mkEnableOption "Enable ${name}";

    package = lib.mkPackageOption pkgs name { };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/arrs/${name}";
      description = "data directory for ${name}";
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    group = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    uid = lib.mkOption {
      type = lib.types.str;
      default = uid;
    };
    gid = lib.mkOption {
      type = lib.types.str;
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
    };
    skyg.server.arrs.database = {
      port = lib.mkOption {
        type = lib.types.int;
        default = dbPort;
      };
      dataDir = lib.mkOption {
        description = "Data folder for db";
        type = lib.types.str;
        default = "/var/lib/postgresql/arrs";
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
