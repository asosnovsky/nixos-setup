{ config, pkgs, ... }:

{
  # imports = [ ./hardware-configuration.nix ];
  skyg = {
    user.enable = true;
    nixos.common = {
      ssh-server.enable = true;
      containers.openMetricsPort = true;
    };
    server.exporters.enable = true;
    networkDrives = {
      enable = true;
    };
  };

  # firmware updater
  services.fwupd.enable = true;

  # # ── Boot ──────────────────────────────────────────────────────────────────

  # # ── Networking ────────────────────────────────────────────────────────────
  # networking.hostName = "bigbox2";
  # networking.networkmanager.enable = true;

  # # ── Locale / Time ─────────────────────────────────────────────────────────
  # time.timeZone = "America/Toronto";
  # i18n.defaultLocale = "en_CA.UTF-8";

  # # ── User ──────────────────────────────────────────────────────────────────
  # users.users.ari = {
  #   isNormalUser = true;
  #   description  = "Ari";
  #   extraGroups  = [ "wheel" "networkmanager" ];
  #   shell        = pkgs.bash;
  #   # Set a password after install with: passwd ari
  # };

  # # Allow sudo for wheel group
  # security.sudo.wheelNeedsPassword = true;

  # # ── Base packages ─────────────────────────────────────────────────────────
  # environment.systemPackages = with pkgs; [
  #   vim
  #   git
  #   wget
  #   curl
  #   htop
  #   btrfs-progs
  #   mdadm
  # ];

  # # ── SSH ───────────────────────────────────────────────────────────────────
  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = true;  # change to false once keys are set up
  # };

  # system.stateVersion = "25.05";
}
