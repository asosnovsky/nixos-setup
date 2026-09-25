{ config, pkgs, ... }:
{
  age.secrets.cloudflare-dns.file = ../secrets/cloudflare-dns.age;

  skyg.server.acme = {
    enable = true;
    credentialsFile = config.age.secrets.cloudflare-dns.path;
    certs."buzz.home.sosnovsky.ca" = {
      postRun = "${pkgs.docker}/bin/docker restart buzz-caddy-1";
      orderBefore = [ "container-services-buzz" ];
    };
  };
}
