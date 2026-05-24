mod config;
mod generators;
mod network;

use config::Config;
use std::io::{self, Read};

fn main() {
    let cmd = std::env::args().nth(1).unwrap_or_default();

    let mut input = String::new();
    io::stdin()
        .read_to_string(&mut input)
        .expect("failed to read stdin");

    let config: Config = serde_json::from_str(&input).expect("invalid config JSON");

    let output = match cmd.as_str() {
        "dnsmasq" => generators::dnsmasq::generate(&config),
        "ethers" => generators::ethers::generate(&config),
        _ => {
            eprintln!("usage: openwrt-gen <dnsmasq|ethers>");
            std::process::exit(1);
        }
    };

    print!("{}", output);
}
