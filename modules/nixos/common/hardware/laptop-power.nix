{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.laptop-power-mgr;

  # Script that logs CPU/GPU temps to journal and fires desktop
  # notifications when temperatures cross warning / critical thresholds.
  temp-monitor-script = pkgs.writeShellScript "temp-monitor" ''
    ${pkgs.python3}/bin/python3 << 'EOFPYTHON'
    import subprocess, time, os, re, sys

    WARN_TEMP  = 80.0   # °C — sends a normal notification
    CRIT_TEMP  = 90.0   # °C — sends an urgent notification
    INTERVAL   = 30     # seconds between readings
    COOLDOWN   = 300    # seconds before repeating the same alert level

    def read_temp(chip, label):
        try:
            r = subprocess.run(["${pkgs.lm_sensors}/bin/sensors", chip],
                               capture_output=True, text=True, timeout=5)
            for line in r.stdout.splitlines():
                if label in line:
                    m = re.search(r"\+?([0-9]+\.[0-9]+)", line)
                    if m:
                        return float(m.group(1))
        except Exception:
            pass
        return None

    def notify(urgency, title, body):
        """Send a desktop notification to every logged-in user session."""
        try:
            for entry in os.scandir("/run/user"):
                bus = os.path.join(entry.path, "bus")
                if os.path.exists(bus):
                    env = os.environ.copy()
                    env["DBUS_SESSION_BUS_ADDRESS"] = f"unix:path={bus}"
                    try:
                        subprocess.run(
                            ["${pkgs.libnotify}/bin/notify-send",
                             "--urgency", urgency, title, body],
                            env=env, timeout=5, capture_output=True)
                    except Exception as e:
                        print(f"notify-send failed: {e}", file=sys.stderr, flush=True)
        except Exception as e:
            print(f"Could not scan /run/user: {e}", file=sys.stderr, flush=True)

    print(f"Temp monitor started  warn={WARN_TEMP}°C  crit={CRIT_TEMP}°C  interval={INTERVAL}s",
          flush=True)

    last_warn = 0
    last_crit = 0

    while True:
        now = time.time()
        cpu = read_temp("k10temp-pci-00c3", "Tctl")
        gpu = read_temp("amdgpu-pci-c100",  "edge")

        cpu_s = f"{cpu:.1f}°C" if cpu is not None else "N/A"
        gpu_s = f"{gpu:.1f}°C" if gpu is not None else "N/A"
        print(f"CPU: {cpu_s}  GPU: {gpu_s}", flush=True)

        if cpu is not None:
            if cpu >= CRIT_TEMP and (now - last_crit) > COOLDOWN:
                notify("critical",
                       "🔥 CPU Critical Temperature",
                       f"CPU is at {cpu:.0f}°C — above {CRIT_TEMP:.0f}°C!")
                last_crit = now
            elif cpu >= WARN_TEMP and (now - last_warn) > COOLDOWN:
                notify("normal",
                       "⚠️ CPU High Temperature",
                       f"CPU is at {cpu:.0f}°C — above {WARN_TEMP:.0f}°C")
                last_warn = now

        time.sleep(INTERVAL)
    EOFPYTHON
  '';

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

  # Safety net: if the lid is closed but the machine is still awake, force a
  # suspend. Runs every minute via lid-suspend-watchdog.timer. Rescues the
  # "closed laptop in a bag, sitting awake and overheating" failure mode where
  # logind missed the lid event or the compositor wedged before sleep.
  lid-suspend-watchdog-script = pkgs.writeShellScript "lid-suspend-watchdog" ''
    set -u
    LID_GLOB="/proc/acpi/button/lid/*/state"
    STAMP="/run/lid-suspend-watchdog.stamp"
    COOLDOWN=90

    lid_closed() {
        for f in $LID_GLOB; do
            [ -f "$f" ] || continue
            grep -q "closed" "$f" && return 0
        done
        return 1
    }

    if ! lid_closed; then
        rm -f "$STAMP"
        exit 0
    fi

    # Already suspending/suspended, or a suspend job is queued: nothing to do.
    if systemctl is-active --quiet suspend.target; then
        exit 0
    fi
    if systemctl list-jobs --no-legend 2>/dev/null | grep -q "suspend.target"; then
        exit 0
    fi

    now=$(date +%s)
    last=$(cat "$STAMP" 2>/dev/null || echo 0)
    if [ $((now - last)) -ge "$COOLDOWN" ]; then
        echo "$now" > "$STAMP"
        echo "lid-suspend-watchdog: lid closed and system still awake — forcing suspend"
        systemctl suspend
    fi
  '';
in
{
  options.skyg.nixos.common.hardware.laptop-power-mgr = with lib; {
    enable = mkEnableOption "Settings for laptop power management";

    enableLidSuspendWatchdog = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable a safety-net watchdog that periodically checks the lid switch
        and forces a suspend whenever the lid is closed but the machine is
        still awake (e.g. logind missed the lid event, or the compositor
        wedged on s2idle). Without this, a laptop can sit closed in a bag,
        fully awake, and overheat.
      '';
    };

    enableTempMonitor = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable a background service that logs CPU and GPU temperatures to the
        journal every 30 seconds and sends a desktop notification when the CPU
        crosses 80 °C (warning) or 90 °C (critical).
      '';
    };

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
    # thermald is Intel-only; it exits immediately on AMD machines and
    # provides no thermal protection there. Do not enable it.
    services.thermald.enable = false;
    services.power-profiles-daemon.enable = true;

    # power-profiles-daemon remembers the last selected profile across
    # reboots, so a one-time switch to "performance" would otherwise stick
    # forever and cause constant overheating. Reset to "balanced" at boot
    # and also set a conservative CPU energy policy (balance_power) so the
    # chassis stays cooler when idle.
    # Wanted by graphical.target, not multi-user.target: the daemon is
    # After=multi-user.target upstream, so ordering this unit before
    # multi-user.target forms a cycle and systemd drops the job.
    systemd.services.reset-power-profile = {
      description = "Reset power profile to balanced + conservative EPP at boot";
      wantedBy = [ "graphical.target" ];
      after = [ "power-profiles-daemon.service" "multi-user.target" ];
      wants = [ "power-profiles-daemon.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.writeShellScript "reset-power-and-epp" ''
          ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced
          for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
            echo balance_power > "$f" 2>/dev/null || true
          done
        ''}";
      };
    };
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
          HandleLidSwitchDocked = "ignore";
        } else {
          HandleLidSwitch = "suspend";
          HandleLidSwitchExternalPower = "suspend";
          # Don't suspend when docked to an external screen.
          HandleLidSwitchDocked = "ignore";
        });
      };
    };

    # Add libnotify for notifications (needed for lid monitoring)
    environment.systemPackages = with pkgs; [
      libnotify
    ];

    # Background temperature monitor — logs to journal, alerts when hot
    systemd.services.temp-monitor = lib.mkIf cfg.enableTempMonitor {
      description = "CPU/GPU temperature monitor";
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        ExecStart = "${temp-monitor-script}";
        Restart = "on-failure";
        RestartSec = 10;
        StandardOutput = "journal";
        StandardError = "journal";
      };
    };

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

    # Safety-net suspend watchdog: periodically check the lid, suspend if the
    # lid is closed but the machine is still awake. Only enabled if
    # enableLidSuspendWatchdog is true.
    systemd.services.lid-suspend-watchdog = lib.mkIf cfg.enableLidSuspendWatchdog {
      description = "Force suspend when the lid is closed but the system is still awake";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${lid-suspend-watchdog-script}";
      };
    };

    systemd.timers.lid-suspend-watchdog = lib.mkIf cfg.enableLidSuspendWatchdog {
      description = "Periodic lid-closed suspend check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "1m";
        AccuracySec = "10s";
      };
    };
  };
}
