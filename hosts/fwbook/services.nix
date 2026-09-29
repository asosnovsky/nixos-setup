{ pkgs, unstablePkgs, config, ... }:
{
  services.tailscale.enable = true;
  services.tailscale.extraDaemonFlags = [ "--statedir=/var/lib/tailscale" ];

  programs.tether = {
    enable = true;
    wifi = {
      enable = true;
      openFirewall = true;
    };
    bluetooth = {
      enable = true;
      adapters = [ "hci0" ];
    };
  };

  services.flatpak.enable = true;
  services.flatpak.packages = [
    "io.github.kolunmi.Bazaar"
    "com.spotify.Client"
    "org.pipewire.Helvum"
    "com.cassidyjames.butler"
    "io.dbeaver.DBeaverCommunity"
    "com.google.Chrome"
    "dev.deedles.Trayscale"
  ];

  programs.kdeconnect.enable = true;

  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    package = unstablePkgs.ollama-rocm;
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "11.0.2";
    };
  };
  services.xserver.videoDrivers = [
    "modesetting"
    "fbdev"
  ];
}
