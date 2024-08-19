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
  imports = (if enableSSH then
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
