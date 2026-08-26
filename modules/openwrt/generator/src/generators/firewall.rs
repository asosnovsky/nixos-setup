use crate::config::Config;
use crate::network::{prefix_for, process_network, ULA_PREFIX};

/// Renders UCI firewall rules (in `uci batch` format) that restrict the networks
/// listed in `config.internet_only` to internet-only access.
///
/// For each restricted network:
/// - IPv4: a single DROP rule matching the whole subnet (catches all devices on it).
/// - IPv6: a DROP rule per known device MAC (all subnets share one /64, so subnets
///   are not distinguishable in IPv6).
///
/// Rules are named `skyg_<network>_drop_lan[_v6]` so the deploy script can manage
/// exactly the rules it owns. They are inserted before port-specific ACCEPT rules
/// (e.g. the existing `sambasharelan`) so the DROPs win.
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
            "config rule\n\
             \toption name 'skyg_{net}_drop_lan'\n\
             \toption src 'lan'\n\
             \toption dest 'lan'\n\
             \toption src_ip '{subnet}'\n\
             \toption dest_ip '10.0.0.0/16'\n\
             \toption target 'DROP'\n\
             \toption family 'ipv4'\n",
            net = network,
            subnet = v4_subnet,
        ));

        // IPv6: block each known device's MAC from reaching the ULA LAN.
        for pd in process_network(network, devices) {
            out.push_str(&format!(
                "config rule\n\
                 \toption name 'skyg_{net}_drop_lan_v6'\n\
                 \toption src 'lan'\n\
                 \toption dest 'lan'\n\
                 \toption src_mac '{mac}'\n\
                 \toption dest_ip '{ula}'\n\
                 \toption target 'DROP'\n\
                 \toption family 'ipv6'\n",
                net = network,
                mac = pd.device.mac,
                ula = ULA_PREFIX,
            ));
        }
    }

    out
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
                },
                Device {
                    mac: "aa:bb:cc:dd:ee:02".to_string(),
                    name: "cam2".to_string(),
                    id: None,
                    domains: None,
                    just_mac: false,
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
    fn test_unknown_network_is_skipped() {
        let config = config_with_devices(vec!["nonexistent".to_string()]);
        let result = generate(&config);
        assert!(result.lines().count() == 1); // only the header comment
    }
}
