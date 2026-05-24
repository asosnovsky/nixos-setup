use crate::config::Config;
use crate::network::process_network;

pub fn generate(config: &Config) -> String {
    let mut out = String::new();

    for (network, devices) in &config.networks {
        let cap = |s: &str| {
            let mut c = s.chars();
            match c.next() {
                None => String::new(),
                Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
            }
        };
        out.push_str(&format!("#{}\n", cap(network)));

        for pd in process_network(network, devices) {
            if !pd.just_mac {
                out.push_str(&format!("{} {}\n", pd.device.mac, pd.ip));
            }
            out.push_str(&format!("{} {}\n", pd.device.mac, pd.host));
        }
    }

    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{Config, Device};
    use std::collections::BTreeMap;

    fn config_with_device(just_mac: bool) -> Config {
        let mut networks = BTreeMap::new();
        networks.insert("lab".to_string(), vec![Device {
            mac: "aa:bb:cc:dd:ee:ff".to_string(),
            name: "server".to_string(),
            id: None,
            domains: None,
            just_mac,
        }]);
        Config { general_mappings: vec![], networks, dns_resolvers: vec![] }
    }

    #[test]
    fn test_generates_ip_and_hostname() {
        let result = generate(&config_with_device(false));
        assert!(result.contains("aa:bb:cc:dd:ee:ff 10.0.10.1\n"));
        assert!(result.contains("aa:bb:cc:dd:ee:ff server.lab.internal\n"));
    }

    #[test]
    fn test_just_mac_omits_ip_line() {
        let result = generate(&config_with_device(true));
        assert!(!result.contains("10.0.10.1"));
        assert!(result.contains("aa:bb:cc:dd:ee:ff server.lab.internal\n"));
    }

    #[test]
    fn test_network_header_capitalized() {
        let result = generate(&config_with_device(false));
        assert!(result.contains("#Lab\n"));
    }

    #[test]
    fn test_empty_config() {
        let config = Config {
            general_mappings: vec![],
            networks: BTreeMap::new(),
            dns_resolvers: vec![],
        };
        assert!(generate(&config).is_empty());
    }
}
