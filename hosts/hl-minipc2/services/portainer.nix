{ ... }:
{
  age.secrets.portainer-tls-key.file = ../secrets/portainer-tls-key.age;

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "server";
    server.tls = {
      enable = true;
      cert = builtins.readFile ../configs/pki/portainer.app.internal.crt;
      keySecretName = "portainer-tls-key";
    };
  };
}
