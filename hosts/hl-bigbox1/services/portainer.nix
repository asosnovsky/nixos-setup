{ config, skyg-secrets, ... }:
{
  age.secrets.portainer-agent-bigbox1.file = skyg-secrets.portainer-agent-bigbox1;

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "agent";
    agent.edgeKeySecretName = "portainer-agent-bigbox1";
  };
}
