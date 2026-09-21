{ lib
, config
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.pipewire;
in
{
  options.skyg.nixos.common.hardware.pipewire = with lib; {
    enable = mkEnableOption "pipewire audio stack";
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      audio.enable = true;
      wireplumber.enable = true;
      pulse.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      systemWide = false;
      socketActivation = true;
    };
    services.jack.alsa.enable = true;
  };
}
