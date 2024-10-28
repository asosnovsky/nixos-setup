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

  config = lib.mkIf cfg.enable {
    # resolve master hostname
    networking.extraHosts = "${cfg.masterIP} ${cfg.masterHostName}";

    # packages for administration tasks
    environment.systemPackages = with pkgs; [
      kompose
      kubectl
      kubernetes
    ];
    services.kubernetes = {
      masterAddress = cfg.masterHostName;
      easyCerts = true;
      apiserverAddress = "https://${cfg.masterHostName}:${toString cfg.masterAPIPort}";
      addons.dns.enable = true;
      kubelet.extraOpts = "--fail-swap-on=false";

    };
  };
}
