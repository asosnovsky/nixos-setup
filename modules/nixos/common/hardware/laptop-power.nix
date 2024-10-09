{ lib
, config
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.laptop-power-mgr;
in
{
  options.skyg.nixos.common.hardware.laptop-power-mgr = with lib; {
    enable = mkEnableOption "Settings for laptop power management";
  };

  config = lib.mkIf cfg.enable {
    # Advance Power Management
    powerManagement.powertop.enable = true;
    powerManagement.enable = true;
    services.thermald.enable = true;
    services.power-profiles-daemon.enable = false;
    services.tlp = {
      enable = true;
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
    services.auto-cpufreq.enable = true;
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
    systemd.sleep.extraConfig = "HibernateDelaySec=30m";
    # Logind
    services.logind = {
      lidSwitchExternalPower = "suspend-then-hibernate";
      lidSwitch = "suspend-then-hibernate";
      powerKey = "lock";
      extraConfig = ''
        LidSwitchIgnoreInhibited=yes
        HandlePowerKey=suspend-then-hibernate
        IdleAction=suspend-then-hibernate
        IdleActionSec=2m
      '';
    };
  };
}
