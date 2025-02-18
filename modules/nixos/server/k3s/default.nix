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
        default = "/mnt/EightTerra/k3s-cluster/configs/k3s.env";
      };
    };
  };

  config =
    lib.mkIf cfg.enable {
      system.activationScripts.k3sEnv = ''
        set -e
        mkdir -p /var/lib/k3s
        cp ${cfg.envPath} /var/lib/k3s/.env 
        chmod 0644 /var/lib/k3s/.env
        chown root:root /var/lib/k3s/.env
      '';
      services.k3s = {
        enable = true;
        environmentFile = "/var/lib/k3s/.env";
        role = cfg.role;
      };
    };
}
