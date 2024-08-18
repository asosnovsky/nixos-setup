{ lib, pkgs, ... }:

with lib;

{
  options = {
    skyg.desktop = {
      fonts = mkOption {
        description = "Preferred Font";
        type = types.package;
        default = pkgs.fira-code;
      };
    };
  };

  config = { };
}
