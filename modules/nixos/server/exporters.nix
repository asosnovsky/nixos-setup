{ config, lib, ... }:
let cfg = config.skyg.server.exporters;
in {
  options = {
    skyg.server.exporters = {
      enable = lib.mkEnableOption
        "Enable Special prom exporters for servers";
    };
  };
  config = lib.mkIf cfg.enable {
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
