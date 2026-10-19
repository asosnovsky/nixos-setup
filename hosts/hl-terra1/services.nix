{ ... }:
{
  skyg.nixos.common.networking.nfsServer.enable = true;
  services.skyg-linux-tracker = {
    enable = true;
    bind = "0.0.0.0";
    openFirewall = true;
    # Reachable only by its lab FQDN; the short name does not resolve.
    allowedHosts = [ "terra1.lab.internal" ];
    # OTLP out to the collector on minipc1.
    settings.otel = {
      enabled = true;
      endpoint = "http://minipc1.lab.internal:4317";
      protocol = "grpc";
      export_logs = true;
    };
  };
  services.nfs.server = {
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
    extraNfsdConfig = '''';
    exports = ''
      /mnt/Data/apps  10.0.0.0/16(rw,wdelay,insecure,no_root_squash,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash)
    '';
  };
}
