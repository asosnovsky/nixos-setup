{ user
, systemStateVersion
, hostName
, system
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
      enableNetowrking = os.enableNetowrking;
      enableSSH = os.enableSSH;
      hardware = os.hardware;
    })
  ] else [ ]) ++ (if home-manager.enable then [
    (import ./home-manager/common.nix {
      user = user;
      homeMangerVersion = home-manager.version;
      hostName = hostName;
    })
  ] else [ ])
  ;
}
