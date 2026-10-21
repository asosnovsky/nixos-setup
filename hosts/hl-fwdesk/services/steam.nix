{ pkgs, ... }:
{
  programs.steam = {
    enable = true;
    extest.enable = true;
    extraPackages = [ pkgs.pulseaudio ];
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  hardware.xone.enable = true;
}
