{ user
, hostName
, firewall
, enableFonts ? true
, enableNetworking ? true
, enableSSH ? true
, containers ? { runtime = null; }
, hardware ? { enable = false; }
, enablePrometheusExporters ? false
, ...
}:
{ pkgs, ... }: {
  imports = [
    (import ./user.nix { user = user; })
    (import ./containers/default.nix ({
      user = user;
    } // containers))
  ] ++ (if enableFonts then [ ./fonts.nix ] else [ ])
  ++ (if hardware.enable then [ ./hardware.nix ] else [ ])
  ++ (if enableNetworking then
    [
      (import ./networking.nix {
        hostName = hostName;
        firewall = firewall;
      })
    ]
  else
    [ ]) ++ (if enableSSH then
    [
      (import ./ssh.nix {
        enableSSHServer = true;
        user = user;
      })
    ]
  else
    [ ])
  ++ (if enablePrometheusExporters then [ ./exporters.nix ] else [ ]);
}
