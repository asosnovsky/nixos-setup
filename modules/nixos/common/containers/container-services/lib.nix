{ lib, pkgs }:

{
  # Runtime dispatch
  isDocker = runtime: runtime == "docker";

  composeBin = runtime:
    if lib.hasAttrByPath [ "docker" ] pkgs
    then
      (if runtime == "docker"
      then "${pkgs.docker-compose}/bin/docker-compose"
      else "${pkgs.podman-compose}/bin/podman-compose")
    else
      (if runtime == "docker"
      then "docker-compose"
      else "podman-compose");

  runtimeService = isDocker:
    if isDocker then "docker.service" else "podman.service";

  # Collect all env files from all services in a group
  getAllEnvFiles = grpCfg:
    lib.concatLists
      (lib.attrValues
        (lib.mapAttrs (_: svcCfg: svcCfg.environmentFiles) grpCfg.services));

  # Sanitize a path into a valid filename
  pathToFilename = target:
    lib.strings.sanitizeDerivationName (
      builtins.replaceStrings [ "/" ] [ "-" ]
        (lib.strings.removePrefix "/" target)
    );
}
