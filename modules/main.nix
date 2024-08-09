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
{ ... }: {
  imports = [
    (import ./skyg)
    (import ./nix {
      user = user;
      systemStateVersion = systemStateVersion;
      localNixCaches = localNixCaches;
    })
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
  skyg.user = user;
  skyg.home-manager.version = homeManagerVersion;
}
