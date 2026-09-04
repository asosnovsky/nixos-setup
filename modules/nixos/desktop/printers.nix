{ pkgs, lib, config, ... }:
{
  options = {
    skyg.nixos.desktop.printers = {
      enable = lib.mkEnableOption "Enable Printers";
    };
  };
  config = lib.mkIf config.skyg.nixos.desktop.printers.enable {

    services.flatpak.overrides = {
      "org.chromium.Chromium" = {
        Context = {
          sockets = [ "cups" ];
        };
      };
    };
    services.printing = {
      enable = true;
      drivers = with pkgs; [
        gutenprint
        hplip
        splix
        epson-escpr2
        epson-escpr
        epsonscan2
        gutenprint
      ];
    };
  };
}
