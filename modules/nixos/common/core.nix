{ pkgs, config, lib, ... }:
{
  options.skyg = {
    gc = {
      rootDays = lib.mkOption {
        type = lib.types.int;
        description = "How often (in days) we call 'nix-collect-garbage' on root user";
        default = 7;
      };
      userDays = lib.mkOption {
        type = lib.types.int;
        description = "How often in (days) we call 'nix-collect-garbage' on skyg.user.name";
        default = 7;
      };
    };
  };
  config = let skyg = config.skyg; in {

    # System Packages
    services.hydra.useSubstitutes = true;
    programs.dconf.enable = true;
    programs.nix-ld.enable = true;
    nixpkgs.config.allowUnfree = true;
    nix = {
      optimise.automatic = true;
      settings.experimental-features = [ "nix-command" "flakes" ];
    };
    programs.nh = {
      enable = true;
      clean.enable = true;
    };
    environment.systemPackages = with pkgs; [
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
        "0 23 * * *       root    nix-collect-garbage --delete-older-than ${toString skyg.gc.rootDays}d"
        "0 23 * * *       ${skyg.user.name}   nix-collect-garbage --delete-older-than ${toString skyg.gc.userDays}d"
      ];
    };
  };
}
