use serde::Deserialize;
use std::collections::BTreeMap;
use std::io::{self, Read};

const ROOT_DOMAIN: &str = "internal";

static IP_PREFIXES: &[(&str, &str)] = &[
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
static JUST_MAC_NETWORKS: &[&str] = &["devices"];

#[derive(Deserialize)]
struct Config {
    #[serde(rename = "generalMappings")]
    general_mappings: Vec<GeneralMapping>,
    networks: BTreeMap<String, Vec<Device>>,
}

#[derive(Deserialize)]
struct GeneralMapping {
    ip: String,
    domains: Vec<String>,
}

#[derive(Deserialize)]
struct Device {
    mac: String,
    name: String,
    #[serde(default)]
    id: Option<u32>,
    #[serde(default)]
    domains: Option<Vec<String>>,
    #[serde(rename = "justMac", default)]
    just_mac: bool,
}

struct ProcessedDevice<'a> {
    device: &'a Device,
    ip: String,
    host: String,
    just_mac: bool,
}

fn prefix_for(network: &str) -> &'static str {
    IP_PREFIXES
        .iter()
        .find(|(n, _)| *n == network)
        .map(|(_, p)| *p)
        .unwrap_or("10.0.0.")
}

fn process_network<'a>(network: &str, devices: &'a [Device]) -> Vec<ProcessedDevice<'a>> {
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

fn gen_dnsmasq(config: &Config) -> String {
    let mut out = String::new();

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

fn gen_ethers(config: &Config) -> String {
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

fn main() {
    let cmd = std::env::args().nth(1).unwrap_or_default();

    let mut input = String::new();
    io::stdin().read_to_string(&mut input).expect("failed to read stdin");

    let config: Config = serde_json::from_str(&input).expect("invalid config JSON");

    let output = match cmd.as_str() {
        "dnsmasq" => gen_dnsmasq(&config),
        "ethers" => gen_ethers(&config),
        _ => {
            eprintln!("usage: openwrt-gen <dnsmasq|ethers>");
            std::process::exit(1);
        }
    };

    print!("{}", output);
}
