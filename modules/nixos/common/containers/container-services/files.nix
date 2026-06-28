{ lib, pkgs, containerLib }:

rec {
  # Collect all files from all services in a group.
  # Returns: { "<svcName>.<filename>" = { target = "..."; content = "..."; }; }
  getAllFiles = grpCfg:
    lib.foldAttrs lib.recursiveUpdate { }
      (lib.mapAttrsToList
        (svcName: svcCfg:
          lib.mapAttrs'
            (target: content:
              let
                filename = containerLib.pathToFilename target;
              in
              lib.nameValuePair
                "${svcName}/${filename}"
                { inherit target content; }
            )
            svcCfg.files
        )
        grpCfg.services
      );

  # Build file volume mounts for a specific service.
  # Returns: [ "/var/lib/container-services/<group>/files/<filename>:<target>:ro" ]
  mkFileVolumesForService = groupName: svcCfg:
    lib.mapAttrsToList
      (target: _:
        let
          filename = containerLib.pathToFilename target;
          hostPath = "/var/lib/container-services/${groupName}/files/${filename}";
        in
        "${hostPath}:${target}:ro"
      )
      svcCfg.files;

  # Build file volume mounts for all services in a group.
  # Returns: { "svcName" = [ "...mount..." ]; }
  mkFileVolumesForGroup = groupName: grpCfg:
    lib.mapAttrs
      (svcName: svcCfg: mkFileVolumesForService groupName svcCfg)
      grpCfg.services;

  # Generate a shell script that writes all files for a group.
  mkFilesScript = groupName: grpCfg:
    let
      filesMap = getAllFiles grpCfg;
      writeCommands = lib.mapAttrsToList
        (path: fileData:
          let
            filename = containerLib.pathToFilename fileData.target;
            hostPath = "/var/lib/container-services/${groupName}/files/${filename}";
          in
          ''
            mkdir -p "$(dirname "${hostPath}")"
            cat > "${hostPath}" <<'CONTENT'
            ${fileData.content}
            CONTENT
            chmod 0644 "${hostPath}"
          ''
        )
        filesMap;
    in
    lib.concatStringsSep "\n" writeCommands;

  # Create a systemd service that writes files for a group.
  # Only created if the group has files.
  mkFilesService = groupName: grpCfg: pkgs:
    let
      filesMap = getAllFiles grpCfg;
      scriptFile = pkgs.writeShellScript "write-files-${groupName}" (mkFilesScript groupName grpCfg);
    in
    lib.optionalAttrs (filesMap != { }) {
      "container-services-${groupName}-files" = {
        description = "Write custom files for container service group '${groupName}'";
        before = [ "container-services-${groupName}.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = scriptFile;
        };
      };
    };
}
