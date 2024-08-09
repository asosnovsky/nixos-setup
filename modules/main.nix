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
    (import ./skyg)
    (import ./hl-services)
    (import ./hl-hardware)
  ] ++ (if desktop.enable then
    [ (import ./desktop ({ user = user; } // desktop)) ]
  else
    [ ]) ++ (if os.enable then
    [
      (import ./os ({
        user = user;
        hostName = hostName;
      } // os))
    ]
  else
    [ ])
  ++ (if enableNetworkDrives then [ (import ./network-drives.nix) ] else [ ])
  ;
  # Share defaults
  skyg.user = user;
  skyg.home-manager.version = homeManagerVersion;
  skyg.core.substituters = localNixCaches;
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
