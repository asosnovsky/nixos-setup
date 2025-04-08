{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.server.k3s;
in
{
  options = {
    skyg.nixos.server.k3s = {
      enable = lib.mkEnableOption
        "Enable K3s";
      role = lib.mkOption {
        type = lib.types.str;
        default = "server";
      };
      envPath = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config =
    let
      openPorts = [
        6443 # api server
        80
        443
        10250 # metrics
        8472 # flannel
        51820 # wireguard
        10251 # scheduler
        10252 # control manager
      ];
    in
    lib.mkIf cfg.enable {
      services.k3s = {
        enable = true;
        environmentFile = cfg.envPath;
        role = cfg.role;
        extraFlags = [
          "--disable servicelb"
          "write-kubeconfig-mode 640"
          "--write-kubeconfig-group users"
          "--disable-helm-controller"
        ];
      };
      networking.firewall.allowedUDPPorts = openPorts;
      networking.firewall.allowedTCPPorts = openPorts;
    };
}
