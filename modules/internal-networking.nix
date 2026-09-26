# Renders the global `skyg.internalNetworkingMap` into the shape the OpenWrt
# generator consumes (`generalMappings`).
#
# Usage:
#   internalNetworking = import ./modules/internal-networking.nix { inherit lib; };
#   internalNetworking.records apps      # -> [ { ip; domains; ... } ]
#   internalNetworking.json    apps      # -> { generalMappings = [...]; }
#
# The map is global (identical on every host), so there is nothing to aggregate
# across hosts and no cross-host conflicts to detect.
{ lib }:

let
  # One app -> one record. `wildcard = false` keeps the plain host-record
  # behaviour the generator expects for Nix-declared names.
  toRecord = name: app: {
    ip = app.ip;
    domains = [ app.effectiveDns ] ++ lib.optional (app.aliasDns != null) app.aliasDns;
    wildcard = false;
    source = "internalNetworkingMap/${name}";
  };

  records = apps:
    lib.sort (a: b: a.ip < b.ip) (lib.mapAttrsToList toRecord apps);

in
{
  inherit records;

  # The fragment merged into the router's (secret) config JSON at deploy time.
  json = apps: {
    generalMappings = map (r: { inherit (r) ip domains wildcard; }) (records apps);
  };
}
