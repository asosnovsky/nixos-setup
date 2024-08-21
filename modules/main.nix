{ user
, homeManagerVersion
, systemStateVersion
, hostName
, system
, enableNetworkDrives ? false
  # Desktop Module
, desktop ? {
    enable = false;
  }
  # os
, os ? {
    enable = false;
  }
, localNixCaches ? { keys = [ ]; urls = [ ]; }
, ...
}:
{ pkgs, ... }: {
  imports = [
    (import ./core)
    (import ./nixos)
    (import ./network-drives.nix)
  ];
  # Share defaults
  skyg.user = user;
  skyg.core.hostName = hostName;
  skyg.home-manager.version = homeManagerVersion;
  skyg.core.substituters = localNixCaches;
  skyg.networkDrives.enabled = enableNetworkDrives;
  skyg.nixos.common.containers = (if os.enable then os.containers else { });
  system.stateVersion = systemStateVersion;
  nixpkgs.config.allowUnfree = true;
  nix = {
    optimise.automatic = true;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  # System Packages
  environment.systemPackages = with pkgs; [
    # nix utils
    nix-index
    nil
    cachix
    nixpkgs-fmt
    nvd
    # shell tools
    wget
  ];
}
