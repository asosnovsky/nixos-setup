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
    (import ./core.nix {
      user = user;
    })
    ./rootUser.nix
    (import ./user.nix {
      user = user;
    })
    (import ./docker.nix {
      user = user;
    })
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
    (import ./ssh.nix {
      enableSSHServer = true;
      user = user;
    })
  ] else [ ]);
}
