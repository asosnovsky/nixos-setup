{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.common.pritunl;
in
{
  options = {
    skyg.common.pritunl = {
      enable = lib.mkEnableOption "Enable Pritunl";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pritunl-client
    ];
    systemd.services.pritunl-client-service = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Starts the pritunl client service";
      serviceConfig = {
        Type = "simple";
        User = "root";
        ExecStart = ''${pkgs.pritunl-client}/bin/pritunl-client-service'';
      };
    };
  };
}
