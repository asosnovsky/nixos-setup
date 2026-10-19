{ config, pkgs, ... }:
{
  services.fwupd.enable = true;

  # Interim: the box loses power under load. Use less power and heat, log more.
  # Remove this block once the new board is in and stable.

  systemd.tmpfiles.rules = [
    # No turbo. Lost on reboot unless set here.
    "w /sys/devices/system/cpu/cpufreq/boost - - - - 0"
    # Max clock 2.5 GHz. Steps on this CPU: 3.5, 3.0, 2.5, 2.0, 1.4.
    "w /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq - - - - 2500000"
  ];

  # Keep logs on disk and flush often, so the last seconds before a crash survive.
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=2G
    SyncIntervalSec=5s
  '';

  # Reboot 10 s after a kernel panic instead of hanging.
  boot.kernel.sysctl."kernel.panic" = 10;

  # Watch disk health and log warnings. No mail set up.
  services.smartd = {
    enable = true;
    autodetect = true;
  };

  environment.systemPackages = [
    pkgs.smartmontools
    pkgs.lm_sensors
    pkgs.dmidecode
    pkgs.stress-ng
    pkgs.memtester
    pkgs.ethtool
    config.boot.kernelPackages.cpupower
  ];
}
