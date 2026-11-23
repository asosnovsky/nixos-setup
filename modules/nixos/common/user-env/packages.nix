{ config
, lib
, pkgs
, ...
}:
{
  # CLI tools for every user.
  config = lib.mkIf config.skyg.user.enable {
    environment.systemPackages = with pkgs; [
      jq
      htop
      kubectl
      kubectx
      nixpkgs-fmt
      nixd
      ipfetch
      fastfetch
      terraform
      eza
      carapace
    ];
  };
}
