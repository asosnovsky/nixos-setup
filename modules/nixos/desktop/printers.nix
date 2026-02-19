{ pkgs, lib, ... }:
{
  config = {
    services.printing = lib.mkIf cfg.desktop.enable {
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
