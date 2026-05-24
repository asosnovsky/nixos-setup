use crate::config::Config;
use crate::network::process_network;

pub fn generate(config: &Config) -> String {
    let mut out = String::new();

    // Add DNS resolver configuration
    for resolver in &config.dns_resolvers {
        if let Some(port) = resolver.port {
            out.push_str(&format!("server={}#{}", resolver.ip, port));
        } else {
            out.push_str(&format!("server={}", resolver.ip));
        }
        if let Some(name) = &resolver.name {
            out.push_str(&format!(" # {}", name));
        }
        out.push('\n');
    }

    if !config.dns_resolvers.is_empty() {
        out.push('\n');
    }

    for (network, devices) in &config.networks {
        for pd in process_network(network, devices) {
            if pd.just_mac {
                continue;
            }
            if let Some(domains) = &pd.device.domains {
                for domain in domains {
                    out.push_str(&format!("address=/{}/{}\n", domain, pd.ip));
                    out.push_str(&format!("address=/.{}/{}\n", domain, pd.ip));
                }
            }
        }
    }

    for gm in &config.general_mappings {
        for domain in &gm.domains {
            out.push_str(&format!("address=/{}/{}\n", domain, gm.ip));
            out.push_str(&format!("address=/.{}/{}\n", domain, gm.ip));
        }
    }

    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::{Config, Device, DnsResolver, GeneralMapping};
    use std::collections::BTreeMap;

    fn config_with_device(domains: Option<Vec<String>>) -> Config {
        let mut networks = BTreeMap::new();
        networks.insert("lab".to_string(), vec![Device {
            mac: "aa:bb:cc:dd:ee:ff".to_string(),
            name: "server".to_string(),
            id: None,
            domains,
            just_mac: false,
        }]);
        Config { general_mappings: vec![], networks, dns_resolvers: vec![] }
    }

    #[test]
    fn test_device_with_domains() {
        let config = config_with_device(Some(vec!["example.com".to_string()]));
        let result = generate(&config);
        assert!(result.contains("address=/example.com/10.0.10.1\n"));
        assert!(result.contains("address=/.example.com/10.0.10.1\n"));
    }

    #[test]
    fn test_general_mappings() {
        let config = Config {
            general_mappings: vec![GeneralMapping {
                ip: "192.168.1.1".to_string(),
                domains: vec!["gw.local".to_string()],
            }],
            networks: BTreeMap::new(),
            dns_resolvers: vec![],
        };
        let result = generate(&config);
        assert!(result.contains("address=/gw.local/192.168.1.1\n"));
    }

    #[test]
    fn test_dns_resolvers() {
        let config = Config {
            general_mappings: vec![],
            networks: BTreeMap::new(),
            dns_resolvers: vec![DnsResolver {
                ip: "1.1.1.1".to_string(),
                port: Some(853),
                name: Some("CF".to_string()),
            }],
        };
        let result = generate(&config);
        assert!(result.contains("server=1.1.1.1#853 # CF\n"));
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
