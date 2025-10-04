{ pkgs, config, ... }:
{
  # System Packages
  services.hydra.useSubstitutes = true;
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  nixpkgs.config.allowUnfree = true;
  nix = {
    optimise.automatic = true;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  environment.systemPackages = with pkgs; [
    # nix utils
    appimage-run

    # shell tools
    git
    usbutils

    # system utils
    nfs-utils
    lm_sensors
    hwinfo
    dig
    iperf

    # misc
    glib-networking
    glib
    glibc

    # printer
    system-config-printer

    # nix utils
    nix-index
    nil
    cachix
    nixpkgs-fmt
    nvd
    # shell tools
    wget
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Storage Clean up
  services.cron = {
    enable = true;
    systemCronJobs = [
      "* 23 * * *       root    nix-collect-garbage --delete-older-than 7d"
      "* 23 * * *       ${config.skyg.user.name}   nix-collect-garbage --delete-older-than 7d"
    ];
  };
}
