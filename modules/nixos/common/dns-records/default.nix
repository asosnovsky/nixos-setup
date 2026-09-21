{ config, lib, ... }:

let
  cfg = config.skyg.dns;

  # Bare labels get the default domain appended; anything already containing a
  # dot is treated as fully-qualified and left alone.
  qualify = name:
    if lib.hasInfix "." name || cfg.domain == null || cfg.domain == ""
    then name
    else "${name}.${cfg.domain}";

  recordType = lib.types.submodule ({ ... }: {
    options = {
      ip = lib.mkOption {
        type = lib.types.str;
        example = "10.0.101.2";
        description = "IPv4 address the names should resolve to.";
      };

      names = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        example = [ "drawdb" "drawdb.app.internal" ];
        description = ''
          DNS names for this address. Bare labels (no dot) are automatically
          suffixed with skyg.dns.domain.
        '';
      };

      wildcard = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          When true, the record also matches every subdomain
          (dnsmasq `address=/name/ip`). When false, a plain host record is
          emitted (dnsmasq `host-record=name,ip`), which also provides reverse
          PTR lookups.
        '';
      };

      source = lib.mkOption {
        type = lib.types.str;
        default = "manual";
        description = "Free-form provenance marker, used in generated comments.";
      };
    };
  });

  # Fully-qualified, host-tagged view of every record on this machine.
  resolved = map
    (r: {
      inherit (r) ip wildcard source;
      names = map qualify r.names;
      host = config.networking.hostName;
    })
    (cfg.records ++ (lib.attrValues cfg.extraRecords));

in
{
  options.skyg.dns = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Collect internal DNS records declared on this host. Records are pure
        data -- they are aggregated at the flake level and pushed to the router
        by `skyg openwrt`; nothing is configured on the host itself beyond a
        debug dump in /etc/skyg/dns-records.json.
      '';
    };

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = "app.internal";
      example = "lab.internal";
      description = "Default suffix appended to bare (dot-less) record names.";
    };

    records = lib.mkOption {
      type = lib.types.listOf recordType;
      default = [ ];
      description = ''
        Internal DNS records contributed by this host. Modules append to this
        list (see container-services' `dns.names`); prefer `extraRecords` for
        hand-written entries so they can be overridden by name.
      '';
    };

    extraRecords = lib.mkOption {
      type = lib.types.attrsOf recordType;
      default = { };
      example = lib.literalExpression ''
        {
          nas = { ip = "10.0.0.50"; names = [ "nas" "files" ]; };
        }
      '';
      description = ''
        Hand-written DNS records, keyed by an arbitrary name so they can be
        overridden or removed from another module. Merged into `records`.
      '';
    };

    resolved = lib.mkOption {
      type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
      readOnly = true;
      internal = true;
      description = ''
        Read-only: `records` + `extraRecords` with names fully qualified and the
        owning hostname attached. This is what the flake-level aggregator reads.
      '';
    };

    writeDebugFile = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Write the resolved records to /etc/skyg/dns-records.json.";
    };
  };

  config = lib.mkIf cfg.enable {
    skyg.dns.resolved = resolved;

    assertions = lib.flip map resolved (r: {
      assertion = r.names != [ ];
      message = "skyg.dns: record for ${r.ip} (source: ${r.source}) has no names.";
    });

    environment.etc."skyg/dns-records.json" = lib.mkIf (cfg.writeDebugFile && resolved != [ ]) {
      text = builtins.toJSON resolved + "\n";
    };
  };
}
