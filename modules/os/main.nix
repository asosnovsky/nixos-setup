{ user
, hostName
, firewall
, systemStateVersion
, enableCore ? true
, enableFonts ? true
, enableNetowrking ? true
, enableSSH ? true
, hardware ? {
    enable = false;
  }
}:
{ pkgs, ... }:
{
  imports = [
    (import ./nix.nix {
      user = user;
      systemStateVersion = systemStateVersion;
    })
  ] ++ (if enableCore then [
    (import ./core.nix {
      user = user;
    })
  ] else [ ]) ++ (if enableFonts then [
    ./fonts.nix
  ] else [ ]) ++ (if hardware.enable then [
    ./hardware.nix
  ] else [ ]) ++ (if enableNetowrking then [
    (import ./networking.nix {
      hostName = hostName;
      firewall = firewall;
    })
  ] else [ ]) ++ (if enableSSH then [
    (import ./core.nix {
      enableSSHServer = true;
    })
  ] else [ ]);
}
