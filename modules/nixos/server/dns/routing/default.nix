{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.server.dns.routing;

  # Each { domain, ip } generates both exact and wildcard dnsmasq address entries
  addressEntries = concatMap
    ({ domain, ip }: [
      "/${domain}/${ip}"
      "/.${domain}/${ip}"
    ])
    cfg.addresses;
in
{
  options = {
    skyg.server.dns.routing = {
      enable = mkEnableOption "local DNS resolver via dnsmasq";

      addresses = mkOption {
        description = "Static domain-to-IP mappings. Each entry generates both exact and wildcard dnsmasq address= entries.";
        type = types.listOf (types.submodule {
          options = {
            domain = mkOption { type = types.str; };
            ip = mkOption { type = types.str; };
          };
        });
        default = [ ];
      };

      addressesSecretName = mkOption {
        description = ''
          Name of an agenix secret whose decrypted content is a dnsmasq config
          fragment (address= lines). Included via dnsmasq conf-file. Set null to skip.
        '';
        type = types.nullOr types.str;
        default = null;
        example = "dns-addresses.conf";
      };

      upstreamServers = mkOption {
        description = "Upstream DNS servers to forward unresolved queries to.";
        type = types.listOf types.str;
        default = [ "1.1.1.1" "1.0.0.1" ];
      };

      listenAddresses = mkOption {
        description = "IPs to bind. Empty list means listen on all interfaces (dnsmasq default).";
        type = types.listOf types.str;
        default = [ ];
      };

      openFirewall = mkOption {
        description = "Open port 53 UDP/TCP in the firewall.";
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    age.secrets = mkIf (cfg.addressesSecretName != null) {
      ${cfg.addressesSecretName} = {
        file = ../../../../../secrets + "/${cfg.addressesSecretName}.age";
      };
    };

    services.dnsmasq = {
      enable = true;
      settings = {
        address = addressEntries;
        server = cfg.upstreamServers;
      }
      // optionalAttrs (cfg.listenAddresses != [ ]) {
        listen-address = cfg.listenAddresses;
      }
      // optionalAttrs (cfg.addressesSecretName != null) {
        conf-file = config.age.secrets.${cfg.addressesSecretName}.path;
      };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedUDPPorts = [ 53 ];
      allowedTCPPorts = [ 53 ];
    };
  };
}
