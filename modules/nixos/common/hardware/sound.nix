{ lib
, config
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.sound;
in
{
  options.skyg.nixos.common.hardware.sound = with lib; {
    enable = mkEnableOption "sound";
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
    };
    services.jack = {
      alsa.enable = true;
    };
  };
}
