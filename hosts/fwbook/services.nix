{ pkgs, unstablePkgs, ... }:
{
  services.tailscale.enable = true;
  services.tailscale.extraDaemonFlags = [ "--statedir=/var/lib/tailscale" ];

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

  # Bluetooth tray applet
  systemd.user.services.blueman-applet = {
    description = "Blueman applet";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig.ExecStart = "${pkgs.blueman}/bin/blueman-applet";
  };

  programs.steam = {
    enable = true;
    extest.enable = false;
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
