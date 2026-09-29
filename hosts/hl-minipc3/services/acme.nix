{ config, pkgs, skyg-secrets, ... }:
{
  age.secrets.cloudflare-dns.file = skyg-secrets.cloudflare-dns;

  skyg.server.acme = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-dns.path;
    certs."home.sosnovsky.ca" = {
      extraDomains = [ "*.home.sosnovsky.ca" ];
      postRun = "${pkgs.docker}/bin/docker restart caddy-caddy-1";
      orderBefore = [ "container-services-caddy" ];
    };
  };
}
