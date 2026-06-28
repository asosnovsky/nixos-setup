{ lib }:

rec {
  # Build one compose service entry from a service config.
  # Includes both user volumes and file-mounted volumes.
  mkComposeService = groupName: _svcName: svcCfg: fileVolumes:
    {
      image = svcCfg.image;
      restart = svcCfg.restart;
      networks =
        if svcCfg.networks == [ ]
        then [ groupName ]
        else svcCfg.networks;
    }
    // lib.optionalAttrs (svcCfg.command != [ ]) {
      command = svcCfg.command;
    }
    // lib.optionalAttrs ((svcCfg.ports) != [ ]) {
      ports = svcCfg.ports;
    }
    // lib.optionalAttrs ((svcCfg.volumes ++ fileVolumes) != [ ]) {
      volumes = svcCfg.volumes ++ fileVolumes;
    }
    // lib.optionalAttrs (svcCfg.environment != { }) {
      environment = svcCfg.environment;
    }
    // lib.optionalAttrs (svcCfg.environmentFiles != [ ]) {
      env_file = map builtins.toString svcCfg.environmentFiles;
    }
    // lib.optionalAttrs (svcCfg.dependsOn != [ ]) {
      depends_on = svcCfg.dependsOn;
    }
    // svcCfg.extraConfig;

  # Build the full compose document attrset for a group.
  mkComposeAttrs = groupName: grpCfg: fileVolumesByService:
    let
      networks =
        if grpCfg.networks == { }
        then { "${groupName}" = { driver = "bridge"; }; }
        else grpCfg.networks;
    in
    {
      services = lib.mapAttrs
        (svcName: svcCfg:
          mkComposeService groupName svcName svcCfg (fileVolumesByService."${svcName}" or [ ])
        )
        grpCfg.services;
      networks = networks;
    }
    // lib.optionalAttrs (grpCfg.volumes != [ ]) {
      volumes = lib.genAttrs grpCfg.volumes (_: { });
    }
    // grpCfg.extraConfig;

  # Render compose.yml to the Nix store.
  mkComposeFile = pkgs: groupName: grpCfg: fileVolumesByService:
    (pkgs.formats.yaml { }).generate "compose.yml"
      (mkComposeAttrs groupName grpCfg fileVolumesByService);
}
