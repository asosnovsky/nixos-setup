{ config, skyg-secrets, ... }:
let
  # Must match the master's domain on hl-minipc3.
  masterDomain = "minipc3.lab.internal";
in
{
  age.secrets.buildbot-worker-password-fwdesk.file = skyg-secrets.buildbot-worker-password-fwdesk;

  services.buildbot-nix.worker = {
    enable = true;
    name = "hl-fwdesk";
    workers = 4;
    masterUrl = "tcp:host=${masterDomain}:port=9989";
    workerPasswordFile = config.age.secrets.buildbot-worker-password-fwdesk.path;
  };
}
