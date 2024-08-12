{pkgs, ...}: {
  packages = with pkgs; [
    cloudflared
    home-manager
  ];
}