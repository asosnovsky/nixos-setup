use crate::config::Config;
use crate::network::{prefix_for, process_network, ULA_PREFIX};

/// Renders UCI firewall rules (in `uci` declarative import/export syntax — suitable for
/// `uci -m import firewall`) that restrict devices to internet-only access.
///
/// Two sources of restriction:
/// - **Network-level** (`config.internet_only`): for each restricted network,
///   - IPv4: a single DROP rule matching the whole subnet (catches all devices on it).
///   - IPv6: a DROP rule per known device MAC (all subnets share one /64, so subnets
///     are not distinguishable in IPv6).
/// - **Device-level** (a device with `internetOnly: true`): IPv4 + IPv6 DROP rules
///   matched by that device's MAC, on any network.
///
/// Every rule is a real named section (`config rule 'skyg_...'`, name unique per rule) so
/// the deploy script can address and manage exactly the rules it owns. Every rule also sets
/// `proto 'all'` — without it, fw3 defaults to matching TCP+UDP only, which would silently
/// let ICMP (ping) and other protocols through.
pub fn generate(config: &Config) -> String {
    let mut out = String::new();
    out.push_str("# Managed by skyg openwrt — do not edit by hand\n");

    for network in &config.internet_only {
        let devices = match config.networks.get(network) {
            Some(d) => d,
            None => continue, // unknown network name; skip
        };

        // IPv4: block the whole subnet from reaching the rest of the LAN.
        let v4_prefix = prefix_for(network);
        let v4_subnet = format!("{}.0/24", v4_prefix.trim_end_matches('.'));
        out.push_str(&format!(
            "config rule 'skyg_{net}_drop_lan'\n\
             \toption src 'lan'\n\
             \toption dest 'lan'\n\
             \toption src_ip '{subnet}'\n\
             \toption dest_ip '10.0.0.0/16'\n\
             \toption proto 'all'\n\
             \toption target 'DROP'\n\
             \toption family 'ipv4'\n",
            net = network,
            subnet = v4_subnet,
        ));
        out.push_str("\n");

        // IPv6: block each known device's MAC from reaching the ULA LAN.
        for pd in process_network(network, devices) {
            let slug = mac_slug(&pd.device.mac);
            out.push_str(&format!(
                "config rule 'skyg_{net}_drop_lan_v6_{slug}'\n\
                 \toption src 'lan'\n\
                 \toption dest 'lan'\n\
                 \toption src_mac '{mac}'\n\
                 \toption dest_ip '{ula}'\n\
                 \toption proto 'all'\n\
                 \toption target 'DROP'\n\
                 \toption family 'ipv6'\n",
                net = network,
                slug = slug,
                mac = pd.device.mac,
                ula = ULA_PREFIX,
            ));
            out.push_str("\n");
        }
    }

    // Device-level: any device flagged internetOnly, regardless of network.
    for (network, devices) in &config.networks {
        for pd in process_network(network, devices) {
            if !pd.device.internet_only {
                continue;
            }
            let slug = mac_slug(&pd.device.mac);
            out.push_str(&format!(
                "config rule 'skyg_mac_{slug}_drop_lan'\n\
                 \toption src 'lan'\n\
                 \toption dest 'lan'\n\
                 \toption src_mac '{mac}'\n\
                 \toption dest_ip '10.0.0.0/16'\n\
                 \toption proto 'all'\n\
                 \toption target 'DROP'\n\
                 \toption family 'ipv4'\n",
                slug = slug,
                mac = pd.device.mac,
            ));
            out.push_str("\n");
            out.push_str(&format!(
                "config rule 'skyg_mac_{slug}_drop_lan_v6'\n\
                 \toption src 'lan'\n\
                 \toption dest 'lan'\n\
                 \toption src_mac '{mac}'\n\
                 \toption dest_ip '{ula}'\n\
                 \toption proto 'all'\n\
                 \toption target 'DROP'\n\
                 \toption family 'ipv6'\n",
                slug = slug,
                mac = pd.device.mac,
                ula = ULA_PREFIX,
            ));
            out.push_str("\n");
        }
    }

    out
}

/// MAC address without separators, for use in a UCI rule name.
fn mac_slug(mac: &str) -> String {
    mac.replace(':', "")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{Config, Device};
    use std::collections::BTreeMap;

    fn config_with_devices(internet_only: Vec<String>) -> Config {
        let mut networks = BTreeMap::new();
        networks.insert(
            "cam".to_string(),
            vec![
                Device {
                    mac: "aa:bb:cc:dd:ee:01".to_string(),
                    name: "doorbell".to_string(),
                    id: None,
                    domains: None,
                    just_mac: false,
                    internet_only: false,
                },
                Device {
                    mac: "aa:bb:cc:dd:ee:02".to_string(),
                    name: "cam2".to_string(),
                    id: None,
                    domains: None,
                    just_mac: false,
                    internet_only: false,
                },
            ],
        );
        Config {
            general_mappings: vec![],
            networks,
            dns_resolvers: vec![],
            internet_only,
        }
    }

    #[test]
    fn test_no_internet_only_is_empty() {
        let config = config_with_devices(vec![]);
        let result = generate(&config);
        assert!(result.lines().count() == 1); // only the header comment
    }

    #[test]
    fn test_ipv4_subnet_rule() {
        let config = config_with_devices(vec!["cam".to_string()]);
        let result = generate(&config);
        assert!(result.contains("skyg_cam_drop_lan"));
        assert!(result.contains("option src_ip '10.0.13.0/24'"));
        assert!(result.contains("option dest_ip '10.0.0.0/16'"));
        assert!(result.contains("option proto 'all'"));
        assert!(result.contains("option target 'DROP'"));
        assert!(result.contains("option family 'ipv4'"));
    }

    #[test]
    fn test_ipv6_per_mac_rules() {
        let config = config_with_devices(vec!["cam".to_string()]);
        let result = generate(&config);
        assert!(result.contains("skyg_cam_drop_lan_v6"));
        assert!(result.contains("option src_mac 'aa:bb:cc:dd:ee:01'"));
        assert!(result.contains("option src_mac 'aa:bb:cc:dd:ee:02'"));
        assert!(result.contains("option dest_ip 'fd59:de0a:bff5::/48'"));
        assert!(result.contains("option family 'ipv6'"));
    }

    #[test]
    fn test_network_level_v6_rules_have_unique_names_per_device() {
        // Two devices on a network-level-restricted network must not collide on one
        // UCI section name, or only the last device's rule would actually apply.
        let config = config_with_devices(vec!["cam".to_string()]);
        let result = generate(&config);
        assert!(result.contains("config rule 'skyg_cam_drop_lan_v6_aabbccddee01'"));
        assert!(result.contains("config rule 'skyg_cam_drop_lan_v6_aabbccddee02'"));
    }

    #[test]
    fn test_unknown_network_is_skipped() {
        let config = config_with_devices(vec!["nonexistent".to_string()]);
        let result = generate(&config);
        assert!(result.lines().count() == 1); // only the header comment
    }

    #[test]
    fn test_device_level_internet_only() {
        let mut config = config_with_devices(vec![]);
        // Flag one device on a non-restricted network as internet-only.
        config
            .networks
            .entry("lab".to_string())
            .or_insert_with(Vec::new)
            .push(Device {
                mac: "11:22:33:44:55:66".to_string(),
                name: "printer".to_string(),
                id: None,
                domains: None,
                just_mac: false,
                internet_only: true,
            });
        let result = generate(&config);
        assert!(result.contains("skyg_mac_112233445566_drop_lan"));
        assert!(result.contains("skyg_mac_112233445566_drop_lan_v6"));
        assert!(result.contains("option src_mac '11:22:33:44:55:66'"));
        assert!(result.contains("option dest_ip '10.0.0.0/16'"));
        assert!(result.contains("option dest_ip 'fd59:de0a:bff5::/48'"));
        assert!(result.contains("option proto 'all'"));
        // No subnet rules were generated (no network-level internetOnly).
        assert!(!result.contains("skyg_lab_drop_lan\n"));
    }

    #[test]
    fn test_every_rule_blocks_all_protocols() {
        // A DROP rule without `proto` only blocks TCP+UDP (fw3 default) — every rule must
        // explicitly set `proto 'all'` so ICMP (ping) etc. is blocked too, not just TCP/UDP.
        let config = config_with_devices(vec!["cam".to_string()]);
        let result = generate(&config);
        let rule_count = result.matches("config rule").count();
        let proto_count = result.matches("option proto 'all'").count();
        assert_eq!(rule_count, proto_count);
    }

    #[test]
    fn test_mac_slug_strips_colons() {
        assert_eq!(mac_slug("aa:bb:cc:dd:ee:ff"), "aabbccddeeff");
    }
}
