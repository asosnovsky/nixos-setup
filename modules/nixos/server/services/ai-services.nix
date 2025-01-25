{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.nixos.server.services.ai;
  openPorts = [
    11434
    10400
    10300
    10200
  ];
in
{
  options = {
    skyg.nixos.server.services.ai = {
      enable = mkEnableOption
        "Enable AI Services";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = openPorts;
    networking.firewall.allowedTCPPorts = openPorts;
    virtualisation.oci-containers = {
      containers = {
        ollama = {
          autoStart = true;
          image = "ollama/ollama";
          extraOptions = [ "--device=nvidia.com/gpu=all" ];
          ports = [ "11434:11434" ];
          volumes = [ "ollama:/root/.ollama" ];
        };
        openwakeword = {
          autoStart = true;
          image = "rhasspy/wyoming-openwakeword";
          cmd = [ "--preload-model" "ok_nabu" ];
          ports = [ "10400:10400" ];
        };
      };
    };
    services.wyoming = {
      faster-whisper.servers.main-eng = {
        enable = true;
        device = "cpu";
        model = "medium.en";
        language = "en";
        uri = "tcp://0.0.0.0:10300";
      };
      piper.servers.pier = {
        enable = true;
        uri = "tcp://0.0.0.0:10200";
        voice = "en_GB-alan-medium";
      };
    };
  };
}
