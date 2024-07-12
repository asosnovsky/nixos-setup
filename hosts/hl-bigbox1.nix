{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-bigbox1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # environment.systemPackages = with pkgs; [

  # ];
  # Ollama
  services.ollama = {
    enable = true;
    acceleration = "cuda";
    listenAddress = "0.0.0.0:11434";
  };
  # Docker
  #virtualisation.docker.enableNvidia = true;
  # Kernel
  # Nvidia Settings
  hardware.opengl = {
    enable = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  # boot.initrd.kernelModules = [ "amdgpu" "evdi" ];
  # hardware.opengl.extraPackages = with pkgs; [ rocmPackages.clr.icd amdvlk ];
  # home-manager.users.${user.name}.programs.zsh.initExtra = ''
  #   tmux attach || tmux
  # '';
}
