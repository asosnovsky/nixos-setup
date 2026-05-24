use crate::config::Device;

pub const ROOT_DOMAIN: &str = "internal";

pub static IP_PREFIXES: &[(&str, &str)] = &[
    ("lab", "10.0.10."),
    ("k3s", "10.0.11."),
    ("hub", "10.0.12."),
    ("cam", "10.0.13."),
    ("iot", "10.0.14."),
    ("apl", "10.0.15."),
    ("router", "10.0.16."),
    ("devices", "10.0.0."),
];

// Networks where justMac defaults to true
pub static JUST_MAC_NETWORKS: &[&str] = &["devices"];

pub struct ProcessedDevice<'a> {
    pub device: &'a Device,
    pub ip: String,
    pub host: String,
    pub just_mac: bool,
}

pub fn prefix_for(network: &str) -> &'static str {
    IP_PREFIXES
        .iter()
        .find(|(n, _)| *n == network)
        .map(|(_, p)| *p)
        .unwrap_or("10.0.0.")
}

pub fn process_network<'a>(network: &str, devices: &'a [Device]) -> Vec<ProcessedDevice<'a>> {
    let prefix = prefix_for(network);
    let just_mac_default = JUST_MAC_NETWORKS.contains(&network);
    let mut suffix: u32 = 0;
    let mut seen: Vec<u32> = Vec::new();
    let mut result = Vec::new();

    for device in devices {
        let base = device.id.unwrap_or(suffix + 1);
        // Skip any already-used suffixes
        let next = (base..).find(|s| !seen.contains(s)).unwrap();
        suffix = next;
        seen.push(next);

        result.push(ProcessedDevice {
            device,
            ip: format!("{}{}", prefix, next),
            host: format!("{}.{}.{}", device.name, network, ROOT_DOMAIN),
            just_mac: device.just_mac || just_mac_default,
        });
    }

    result
}

#[cfg(test)]
mod tests {
    use super::*;

    fn device(name: &str, id: Option<u32>, just_mac: bool) -> Device {
        Device {
            mac: "aa:bb:cc:dd:ee:ff".to_string(),
            name: name.to_string(),
            id,
            domains: None,
            just_mac,
        }
    }

    #[test]
    fn test_prefix_for_known_and_unknown() {
        assert_eq!(prefix_for("lab"), "10.0.10.");
        assert_eq!(prefix_for("devices"), "10.0.0.");
        assert_eq!(prefix_for("unknown"), "10.0.0.");
    }

    #[test]
    fn test_process_network_generates_ip_and_host() {
        let devices = vec![device("server1", None, false)];
        let result = process_network("lab", &devices);
        assert_eq!(result[0].ip, "10.0.10.1");
        assert_eq!(result[0].host, "server1.lab.internal");
    }

    #[test]
    fn test_process_network_auto_increments_ids() {
        let devices = vec![device("a", None, false), device("b", None, false)];
        let result = process_network("lab", &devices);
        assert_eq!(result[0].ip, "10.0.10.1");
        assert_eq!(result[1].ip, "10.0.10.2");
    }

    #[test]
    fn test_devices_network_defaults_to_just_mac() {
        let devices = vec![device("phone", None, false)];
        let result = process_network("devices", &devices);
        assert!(result[0].just_mac);
    }
}
