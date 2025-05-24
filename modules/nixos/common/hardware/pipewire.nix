{ lib
, config
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.pipewire;
in
{
  options.skyg.nixos.common.hardware.pipewire = with lib; {
    enable = mkEnableOption "pipewire";
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      wireplumber.enable = true;
      pulse.enable = true;
      systemWide = false;
    };
    services.jack = {
      alsa.enable = true;
    };
  };
}
