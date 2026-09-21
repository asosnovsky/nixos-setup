# Aggregates `skyg.dns.resolved` across every nixosConfiguration into the shape
# the OpenWrt generator consumes (`generalMappings`).
#
# Usage:
#   aggregate = import ./modules/dns-aggregate.nix { inherit lib; };
#   aggregate.records self.nixosConfigurations      # -> [ { ip; domains; ... } ]
#   aggregate.json    self.nixosConfigurations      # -> { generalMappings = [...]; }
#
# Evaluation fails if the same name is mapped to two different addresses on any
# host, so drift between hosts is caught at `nix eval` / `nix flake check` time.
{ lib }:

let
  # Per-host records, tagged with the config name they came from.
  collect = nixosConfigurations:
    lib.flatten (lib.mapAttrsToList
      (cfgName: sys:
        map (r: r // { configName = cfgName; })
          (sys.config.skyg.dns.resolved or [ ]))
      nixosConfigurations);

  # name -> list of { ip, wildcard, source, host, configName }
  byName = all:
    lib.foldl'
      (acc: r: lib.foldl'
        (a: name: a // { ${name} = (a.${name} or [ ]) ++ [ r ]; })
        acc
        r.names)
      { }
      all;

  conflicts = all:
    lib.filterAttrs
      (_: entries: lib.length (lib.unique (map (e: e.ip) entries)) > 1)
      (byName all);

  checkConflicts = all:
    let bad = conflicts all;
    in
    if bad == { }
    then all
    else
      throw ''
        skyg.dns: conflicting DNS records across hosts:
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList
          (name: entries: "  ${name} -> ${lib.concatStringsSep ", " (map
            (e: "${e.ip} (${e.configName}: ${e.source})") entries)}")
          bad)}
      '';

  # Collapse to one entry per (ip, wildcard) pair, with sorted unique names.
  records = nixosConfigurations:
    let
      all = checkConflicts (collect nixosConfigurations);
      groups = lib.groupBy (r: "${r.ip}|${lib.boolToString r.wildcard}") all;
    in
    lib.sort (a: b: a.ip < b.ip) (lib.mapAttrsToList
      (_: entries: {
        ip = (lib.head entries).ip;
        wildcard = (lib.head entries).wildcard;
        domains = lib.sort (a: b: a < b) (lib.unique (lib.concatMap (e: e.names) entries));
        sources = lib.sort (a: b: a < b) (lib.unique (map (e: "${e.configName}:${e.source}") entries));
      })
      groups);

in
{
  inherit records;

  # The fragment merged into the router's (secret) config JSON at deploy time.
  json = nixosConfigurations: {
    generalMappings = map (r: { inherit (r) ip domains wildcard; }) (records nixosConfigurations);
  };
}
