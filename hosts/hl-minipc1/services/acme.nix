{ config, pkgs, skyg-secrets, ... }:
{
  age.secrets.cloudflare-dns.file = skyg-secrets.cloudflare-dns;

  skyg.server.acme = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-dns.path;
    certs."buzz.home.sosnovsky.ca" = {
      postRun = "${pkgs.docker}/bin/docker restart buzz-caddy-1";
      orderBefore = [ "container-services-buzz" ];
    };
  };
}
