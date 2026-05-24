use serde::Deserialize;
use std::collections::BTreeMap;

#[derive(Deserialize)]
pub struct Config {
    #[serde(rename = "generalMappings")]
    pub general_mappings: Vec<GeneralMapping>,
    pub networks: BTreeMap<String, Vec<Device>>,
    #[serde(default, rename = "dnsResolvers")]
    pub dns_resolvers: Vec<DnsResolver>,
}

#[derive(Deserialize)]
pub struct GeneralMapping {
    pub ip: String,
    pub domains: Vec<String>,
}

#[derive(Deserialize)]
pub struct DnsResolver {
    pub ip: String,
    #[serde(default)]
    pub port: Option<u16>,
    #[serde(default)]
    pub name: Option<String>,
}

#[derive(Deserialize)]
pub struct Device {
    pub mac: String,
    pub name: String,
    #[serde(default)]
    pub id: Option<u32>,
    #[serde(default)]
    pub domains: Option<Vec<String>>,
    #[serde(rename = "justMac", default)]
    pub just_mac: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_minimal_config() {
        let json = r#"{"generalMappings": [], "networks": {}}"#;
        let config: Config = serde_json::from_str(json).unwrap();
        assert!(config.general_mappings.is_empty());
        assert!(config.networks.is_empty());
        assert!(config.dns_resolvers.is_empty());
    }

    #[test]
    fn test_device_parsing() {
        let json = r#"{
            "generalMappings": [],
            "networks": {
                "lab": [{"mac": "aa:bb:cc:dd:ee:ff", "name": "server1", "id": 42, "justMac": true}]
            }
        }"#;
        let config: Config = serde_json::from_str(json).unwrap();
        let device = &config.networks["lab"][0];
        assert_eq!(device.mac, "aa:bb:cc:dd:ee:ff");
        assert_eq!(device.id, Some(42));
        assert!(device.just_mac);
    }

    #[test]
    fn test_general_mapping_parsing() {
        let json = r#"{"generalMappings": [{"ip": "192.168.1.1", "domains": ["test.local"]}], "networks": {}}"#;
        let config: Config = serde_json::from_str(json).unwrap();
        assert_eq!(config.general_mappings[0].ip, "192.168.1.1");
        assert_eq!(config.general_mappings[0].domains, vec!["test.local"]);
    }

    #[test]
    fn test_dns_resolver_parsing() {
        let json = r#"{"generalMappings": [], "networks": {}, "dnsResolvers": [{"ip": "1.1.1.1", "port": 853, "name": "CF"}]}"#;
        let config: Config = serde_json::from_str(json).unwrap();
        let resolver = &config.dns_resolvers[0];
        assert_eq!(resolver.ip, "1.1.1.1");
        assert_eq!(resolver.port, Some(853));
        assert_eq!(resolver.name, Some("CF".to_string()));
    }
}
