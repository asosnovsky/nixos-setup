{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.server.k8s;
in
{
  imports = [
    ./master.nix
    ./node.nix
  ];
  options = {
    skyg.nixos.server.k8s = {
      enable = lib.mkEnableOption
        "Enable K8s";
      isMaster = lib.mkEnableOption
        "Enable as master";
      masterIP = lib.mkOption {
        type = lib.types.str;
      };
      masterHostName = lib.mkOption {
        type = lib.types.str;
      };
      masterAPIPort = lib.mkOption {
        type = lib.types.number;
        default = 6443;
      };
    };
  };

  config =
    let
      ports = [
        cfg.masterAPIPort # k8s api server
        10250 # kubelet api
        10259 # kubelet scheduler
        10257 # kubelet controller
        8888 # no idea what this is
      ];
      portRanges = [
        { from = 2379; to = 2380; } # etcd
      ];
    in
    lib.mkIf cfg.enable {
      # resolve master hostname
      networking.extraHosts = "${cfg.masterIP} ${cfg.masterHostName}";
      networking.firewall.allowedUDPPorts = ports;
      networking.firewall.allowedUDPPortRanges = portRanges;
      networking.firewall.allowedTCPPorts = ports;
      networking.firewall.allowedTCPPortRanges = portRanges;

      # packages for administration tasks
      environment.systemPackages = with pkgs; [
        kubectl
        kubernetes
      ];
      services.kubernetes = {
        proxy.hostname = cfg.masterHostName;
        masterAddress = cfg.masterHostName;
        easyCerts = true;
        apiserverAddress = "https://${cfg.masterHostName}:${toString cfg.masterAPIPort}";
        addons.dns.enable = true;
        kubelet.extraOpts = "--fail-swap-on=false";
      };
    };
}
