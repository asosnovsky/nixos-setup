{ config, lib, ... }:
let
  cfg = config.skyg.nixos.server.k8s;
in
{
  config = lib.mkIf (cfg.enable && (!cfg.isMaster)) {
    services.kubernetes = {
      roles = [ "node" ];
      kubelet.kubeconfig.server = "https://${cfg.masterHostName}:${toString cfg.masterAPIPort}";
    };
  };
}
