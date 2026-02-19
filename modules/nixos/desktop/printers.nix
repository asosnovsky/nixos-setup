{ pkgs, lib, config, ... }:
{
  config = {
    services.printing = lib.mkIf config.skyg.nixos.desktop.enable {
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
