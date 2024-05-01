{ pkgs, ... }:
{
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  programs.sway.enable = false;
  programs.sway.wrapperFeature.base = true;
  programs.sway.wrapperFeature.gtk = true;
  environment.systemPackages = with pkgs; [

  ];
  services.mpd.enable = true;
  programs.kdeconnect.enable = true;
  services.pipewire.wireplumber.enable = true;
}
