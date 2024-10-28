{ config, lib, ... }:
let
  cfg = config.skyg.nixos.server.k8s;
in
{
  config = lib.mkIf (cfg.enable && cfg.isMaster) {
    services.kubernetes = {
      roles = [ "master" "node" ];
      apiserver = {
        securePort = cfg.masterAPIPort;
        advertiseAddress = cfg.masterIP;
      };
    };
  };
}
