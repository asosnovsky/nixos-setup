{ config, lib, ... }:

let
  cfg = config.skyg.nixos.server.services.dockge;
in
{
  options = {
    skyg.nixos.server.services.dockge = {
      enable = lib.mkEnableOption
        "Enable Scrypted";
      stacksDir = lib.mkOption {
        description =
          "Path to where the stacks are stored";
        default = "/opt/dockge/stacks";
        type = lib.types.str;
      };
      dataDir = lib.mkOption {
        description =
          "Path to where the data dir is stored";
        default = "/opt/dockge/data";
        type = lib.types.str;
      };
      openFirewall = lib.mkOption {
        description =
          "Open ports in the firewall for the Audiobookshelf web interface.";
        default = false;
        type = lib.types.bool;
      };
      port = lib.mkOption {
        description = "The TCP port Audiobookshelf will listen on.";
        default = 5001;
        type = lib.types.port;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall =
      lib.mkIf cfg.openFirewall { allowedTCPPorts = [ cfg.port ]; };
    virtualisation.oci-containers = {
      containers = {
        dockge = {
          autoStart = true;
          image = "louislam/dockge:1";
          ports = [
            "${cfg.port}:5001"
          ];
          volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
            "${cfg.dataDir}:/app/data"
            "${cfg.stacksDir}:/opt/stacks"
          ];
          environment = {
            DOCKGE_STACKS_DIR = "/opt/stacks";
          };
        };
      };
    };
  };
}
