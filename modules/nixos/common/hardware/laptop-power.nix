{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.laptop-power-mgr;

  # Script to monitor lid events and send notifications
  lid-monitor-script = pkgs.writeShellScript "lid-event-monitor" ''
        ${pkgs.python3}/bin/python3 << 'EOFPYTHON'
    import struct
    import sys
    import subprocess
    import os
    import time

    try:
        print("Lid event monitor started - watching /dev/input/event2", file=sys.stderr, flush=True)
        with open('/dev/input/event2', 'rb') as f:
            while True:
                event = f.read(24)
                if not event:
                    break

                tv_sec, tv_usec, evt_type, code, value = struct.unpack('llHHI', event)

                # EV_SW = 5, SW_LID = 0
                if evt_type == 5 and code == 0:
                    status = "CLOSED" if value else "OPEN"
                    print(f"[{time.time()}] Lid event detected: {status}", file=sys.stderr, flush=True)

                    # Try to send notification - look for active user sessions
                    for pid_dir in os.listdir('/proc'):
                        if not pid_dir.isdigit():
                            continue
                        try:
                            environ_path = f'/proc/{pid_dir}/environ'
                            with open(environ_path, 'rb') as ef:
                                env_data = ef.read()
                                env_vars = {}
                                for var in env_data.split(b'\0'):
                                    if b'=' in var:
                                        key, val = var.split(b'=', 1)
                                        env_vars[key.decode('utf-8', errors='ignore')] = val.decode('utf-8', errors='ignore')

                                if 'DISPLAY' in env_vars and 'DBUS_SESSION_BUS_ADDRESS' in env_vars:
                                    try:
                                        subprocess.run([
                                            '${pkgs.libnotify}/bin/notify-send',
                                            'Lid Event',
                                            f'Lid is now {status}'
                                        ], env=env_vars, timeout=5, capture_output=True)
                                        break
                                    except Exception:
                                        pass
                        except (IOError, OSError, ValueError):
                            pass
    except IOError as e:
        print(f"Could not open lid device: {e}", file=sys.stderr, flush=True)
        sys.exit(1)
    except KeyboardInterrupt:
        print("Lid event monitor stopped", file=sys.stderr, flush=True)
    EOFPYTHON
  '';
in
{
  options.skyg.nixos.common.hardware.laptop-power-mgr = with lib; {
    enable = mkEnableOption "Settings for laptop power management";

    enableLidMonitorMode = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable lid event monitoring mode. When enabled, lid close/open events
        are monitored and sent as desktop notifications instead of triggering
        system actions (hibernate/suspend). This is useful when the lid sensor
        is working but you want visibility into lid events without automatic actions.
      '';
    };

    disableLidSwitch = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Disable lid switch handling in logind. When enabled, systemd-logind
        will ignore lid close/open events and not trigger any automatic actions.
        This is useful when the lid sensor is not working properly and causes
        issues (like infinite hibernation loops).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Advance Power Management
    powerManagement.powertop.enable = true;
    powerManagement.enable = true;
    services.thermald.enable = true;
    services.power-profiles-daemon.enable = true;
    services.tlp = {
      enable = false;
      settings = {
        TLP_DEFAULT_MODE = "BAT";
        TLP_PERSISTENT_DEFAULT = 1;

        CPU_BOOST_ON_BAT = 0;
        RUNTIME_PM_ON_BAT = "auto";
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        START_CHARGE_THRESH_BAT0 = 40; # and bellow it starts to charge
        STOP_CHARGE_THRESH_BAT0 = 97; # and above it stops charging
      };
    };
    services.auto-cpufreq.enable = false;
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };

    # Logind configuration - optionally disable lid handling
    services.logind = {
      settings = {
        Login = {
          HandlePowerKey = "lock";
          # Removed: HandleRFKillKey = "ignore"; (not recognized in systemd 258)
        } // (if cfg.disableLidSwitch then {
          HandleLidSwitch = "ignore";
          HandleLidSwitchExternalPower = "ignore";
        } else {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
        });
      };
    };

    # Add libnotify for notifications (needed for lid monitoring)
    environment.systemPackages = with pkgs; [
      libnotify
    ];

    # System service to monitor lid events and send notifications
    # Only enabled if enableLidMonitorMode is true
    systemd.services.lid-event-monitor = lib.mkIf cfg.enableLidMonitorMode {
      description = "Monitor lid switch events and send desktop notifications";
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-logind.service" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${lid-monitor-script}";
        Restart = "on-failure";
        RestartSec = 5;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };
  };
}
