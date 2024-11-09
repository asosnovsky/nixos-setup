{ config, lib, ... }:
let
  cfg = config.skyg.nixos.server.k8s;
in
{
  config = lib.mkIf (cfg.enable && cfg.isMaster) {
    networking.firewall.allowedUDPPorts = [
      8888 # open cfssl
    ];
    networking.firewall.allowedTCPPorts = [
      8888 # open cfssl
    ];
    services.kubernetes = {
      roles = if cfg.isNode then [ "master" "node" ] else [ "master" ];
      apiserver = {
        securePort = cfg.masterAPIPort;
        advertiseAddress = cfg.masterIP;
      };
    };
  };
}
