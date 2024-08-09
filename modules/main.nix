{ user
, homeManagerVersion
, systemStateVersion
, hostName
, system
, enableNetworkDrives ? false
, enableHomelabServices ? false
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
  ++ (if enableHomelabServices then [ (import ./hl-services) ] else [ ])
  ++ (if enableHomelabServices then [ (import ./hl-hardware) ] else [ ])
  ;
  # Share defaults
  skyg.user = user;
  skyg.home-manager.version = homeManagerVersion;
  skyg.core.substituters = localNixCaches;
  system.stateVersion = systemStateVersion;
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    optimise.automatic = true;
    experimental-features = [ "nix-command" "flakes" ];
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
