{ ... }:
{
  age.secrets.portainer-tls-key.file = "${config.skyg.rootDir}/secrets/portainer-tls-key.age";

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "server";
    server.tls = {
      enable = true;
      cert = builtins.readFile "${config.skyg.rootDir}/configs/pki/portainer.app.internal.crt";
      keySecretName = "portainer-tls-key";
    };
  };
}
