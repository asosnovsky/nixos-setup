{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-terra1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModulePackages = with pkgs.linuxPackages; [ it87 ];
  boot.kernelModules = ["coretemp" "it87" "drivetemp"];
systemd.services.fancontrol = {
  enable = true;
  description = "Fan control";
  wantedBy = ["multi-user.target" "graphical.target" "rescue.target"];

  unitConfig = {
    Type = "simple";
  };

  serviceConfig = {
    ExecStart = "${pkgs.lm_sensors}/bin/fancontrol";
    Restart = "always";
  };
};

}

