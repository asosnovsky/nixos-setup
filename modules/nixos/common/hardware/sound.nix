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
    # Enable sound with pipewire.
    sound.enable = true;
    hardware.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
      systemWide = false;
    };
    services.jack = {
      alsa.enable = true;
    };
  };
}
