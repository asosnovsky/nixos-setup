{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.niri.touchscreen-gestures;
in
{
  options = {
    skyg.nixos.desktop.tiler.niri.touchscreen-gestures = {
      enable = lib.mkEnableOption "niri touchscreen gesture support";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.skyg.nixos.desktop.tiler.niri.enable;
        message = "skyg.nixos.desktop.tiler.niri.touchscreen-gestures: niri must be enabled";
      }
    ];

    # Add the package to the system
    environment.systemPackages = with pkgs; [
      niri-touchscreen-gestures
    ];

    # Create a user systemd service that runs the gesture detector
    systemd.user.services.niri-touchscreen-gestures = {
      description = "Niri touchscreen gesture detector";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "niri.service" "graphical-session.target" ];
      requires = [ "niri.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.niri-touchscreen-gestures}/bin/niri-touchscreen-gestures";
        Restart = "on-failure";
        RestartSec = 3;

        # Environment for niri socket and logging
        Environment = [
          "NIRI_SOCKET=%t/niri/socket"
          "RUST_BACKTRACE=1"
        ];

        # Security hardening appropriate for input device access
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/dev/input" "%t/niri" ];

        # Allow binding to input devices
        CapabilityBoundingSet = [ "CAP_SYS_NICE" ];
        DeviceAllow = [ "/dev/input/event* rw" ];
      };
    };
  };
}
