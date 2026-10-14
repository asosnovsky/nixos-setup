{ config, skyg-secrets, ... }:
{
  age.secrets.cloudflare-ddclient.file = skyg-secrets.cloudflare-ddclient;

  services.ddclient = {
    enable = true;
    protocol = "cloudflare";
    username = "token";
    passwordFile = config.age.secrets.cloudflare-ddclient.path;
    usev6 = "disabled";
    domains = [ ];
    extraConfig = ''
      zone=sosnovsky.ca
      *.sosnovsky.ca,*.home.sosnovsky.ca,home.sosnovsky.ca

      zone=skyg.ca
      *.skyg.ca
    '';
  };
}
