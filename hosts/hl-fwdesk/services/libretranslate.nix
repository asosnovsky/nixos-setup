{ ... }:
let
  ports = { libretranslate = 5000; };
in
{
  services.libretranslate = {
    enable = true;
    host = "0.0.0.0";
    port = ports.libretranslate;
    threads = 10;
  };
  systemd.services.libretranslate.environment.ARGOS_DEVICE_TYPE = "cpu";
}
