{ ... }:
{
  services.pipewire = {
    extraConfig.pipewire-pulse."10-raop-discover" = {
      context.modules = [
        { name = "libpipewire-module-raop-discover"; }
      ];
    };
    wireplumber.extraConfig."51-hdmi-tv" = {
      "wireplumber.settings" = {
        "device.restore-profile" = false;
        "device.restore-routes" = false;
      };
      "device.profile.priority.rules" = [
        {
          matches = [{ "device.name" = "alsa_card.pci-0000_00_1f.3"; }];
          actions.update-props.priorities = [ "output:hdmi-stereo" ];
        }
      ];
      "monitor.alsa.rules" = [
        {
          matches = [{ "node.name" = "~alsa_output.*hdmi.*"; }];
          actions.update-props."priority.session" = 2000;
        }
      ];
    };
  };
  security.rtkit.enable = true;

  services.shairport-sync = {
    enable = true;
    arguments = "-o pipewire";
  };

  services.skyg-linux-tracker = {
    enable = true;
    bind = "0.0.0.0";
    openFirewall = true;
    allowedHosts = [ "fws1.lab.internal" ];
    # OTLP out to the collector on minipc1.
    settings.otel = {
      enabled = true;
      endpoint = "http://minipc1.lab.internal:4317";
      protocol = "grpc";
      export_logs = true;
    };
  };
}
