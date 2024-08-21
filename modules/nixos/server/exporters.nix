{ config, lib, ... }:
with lib;
let cfg = config.skyg.server.exporters;
in {
  options = {
    skyg.server.exporters = {
      enable = mkEnableOption
        "Enable Special prom exporters for servers";
    };
  };
  config = mkIf cfg.enable {
    services.prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        openFirewall = true;
        port = 9100;
      };
    };
  };
}
