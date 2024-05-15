{ user
, hostName
, firewall
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
    ./core.nix
  ] ++ (if enableFonts then [
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
