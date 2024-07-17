{ user
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
  # Home Manager
, home-manager ? {
    enable = false;
    enableDevelopmentKit = false;
  }
, ...
}:
{ ... }:
{
  imports = [
    (import ./nix {
      user = user;
      systemStateVersion = systemStateVersion;
    })
  ] ++ (if desktop.enable then [
    (import ./desktop {
      user = user;
      enableKDE = desktop.enableKDE;
      enableHypr = desktop.enableHypr;
      enableX11 = desktop.enableX11;
      enableWine = desktop.enableWine;
    })
  ] else [ ]) ++ (if os.enable then [
    (import ./os {
      user = user;
      hostName = hostName;
      firewall = os.firewall;
      enableFonts = os.enableFonts;
      enableNetworking = os.enableNetworking;
      enableSSH = os.enableSSH;
      hardware = os.hardware;
    })
  ] else [ ]) ++ (if home-manager.enable then [
    (import ./home-manager {
      user = user;
      homeManagerVersion = home-manager.version;
      enableDevelopmentKit = home-manager.enableDevelopmentKit;
      hostName = hostName;
    })
  ] else [ ]) ++ (if enableNetworkDrives then [
    (import ./network-drives)
  ] else [ ])
  ;
}
