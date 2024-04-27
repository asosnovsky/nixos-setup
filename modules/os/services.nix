{ ... }:
{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver = {
    xkb.layout = "us";
    xkb.variant = "";
  };

  # Logind
  services.logind = {
    lidSwitchExternalPower = "suspend-then-hibernate";
    lidSwitch = "suspend-then-hibernate";
    powerKey = "lock";
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=2m
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=30m";
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Yubikey
  services.yubikey-agent.enable = true;

  # Special Cronjobs
  services.cron = {
    enable = true;
    systemCronJobs = [
      "0 0 * * *      root    nix-channel --update >> /var/log/cron/updater.log"
    ];
  };

  # Programs
  programs.tmux = {
    enable = true;
    clock24 = true;
  };
}
