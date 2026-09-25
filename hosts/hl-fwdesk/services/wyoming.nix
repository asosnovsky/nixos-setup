{ ... }:
let
  ports = {
    wyoming = 10400;
    piper = 10200;
    fastWhisper = 10300;
  };
in
{
  services.wyoming = {
    openwakeword = {
      enable = true;
      uri = "tcp://0.0.0.0:${toString ports.wyoming}";
    };
    piper.servers.peta = {
      enable = true;
      uri = "tcp://0.0.0.0:${toString ports.piper}";
      voice = "en_US-danny-low";
    };
    faster-whisper.servers.todd = {
      enable = true;
      uri = "tcp://0.0.0.0:${toString ports.fastWhisper}";
      model = "tiny.en";
      language = "en";
      device = "auto";
    };
  };
}
