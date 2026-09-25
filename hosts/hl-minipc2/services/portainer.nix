{ config, skyg-secrets, ... }:
{
  age.secrets.portainer-tls-key.file = skyg-secrets.portainer-tls-key;

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "server";
    server.tls = {
      enable = true;
      cert = builtins.readFile skyg-secrets.portainer-cert;
      keySecretName = "portainer-tls-key";
    };
  };
}
