{ user }:
{ pkgs, ... }: {
  virtualisation.oci-containers.backend = "podman";
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
      dockerSocket.enable = true;
      autoPrune.enable = true;
      networkSocket.enable = true;
    };
  };
  environment.systemPackages = with pkgs; [ podman-compose ];
}
