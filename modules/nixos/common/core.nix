{ pkgs, config, lib, ... }:
{
  options.skyg = {
    nixos.common.minimal = lib.mkOption {
      type = lib.types.bool;
      description = "Minimal common system: skip heavy always-on packages for lean hosts.";
      default = false;
    };
    nixos.common.nh.flake = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "Flake path for 'nh os' commands. Set per host.";
      default = null;
    };
  };
  config = {

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
      flake = config.skyg.nixos.common.nh.flake;
      clean = {
        enable = true;
        extraArgs = lib.mkDefault "--keep-since 7d --keep 5";
      };
    };
    environment.systemPackages =
      (with pkgs; [
        # shell tools
        git
        usbutils

        # shell tools
        wget
      ])
      # On lean hosts, skip the heavy server/nix-dev extra tools.
      ++ (lib.optionals (!config.skyg.nixos.common.minimal) (with pkgs; [
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
      ]));
    services.xserver.excludePackages = with pkgs; [
      xterm
    ];
    # Set your time zone.
    time.timeZone = "America/Toronto";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_CA.UTF-8";
  };
}
