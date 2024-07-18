{ ... }: {
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [ "process" "systemd" ];
      openFirewall = true;
    };
    # systemd.enable = true;
    # process.enable = true;
  };
}
