# Temperature Monitor Script

A nushell script for monitoring your laptop's CPU/GPU temperatures, storing them with timestamps, and visualizing them as a graph.

## Features

- **Real-time monitoring**: Collects temperature readings at configurable intervals
- **Persistent storage**: Saves all readings to a CSV file with timestamps
- **Multiple sources**: Tries multiple methods to read temperature data (lm_sensors, acpi, sysfs)
- **ASCII graphs**: Displays temperature data as an ASCII bar graph
- **Flexible configuration**: Customize duration, interval, and output location

## Requirements

The script automatically detects and uses available tools. It will try these in order:
1. `sensors` (from `lm_sensors`) - **Recommended** - Most reliable
2. `acpi` - Fallback option
3. `/sys/class/thermal/thermal_zone0/temp` - Linux sysfs fallback

On NixOS, you can add these to your environment with:
```nix
environment.systemPackages = with pkgs; [
  lm_sensors
  acpi
];
```

## Usage

### Basic usage (60-second collection with 2-second intervals)
```bash
./bin/temp-monitor
```

### Collect for 5 minutes with 5-second intervals
```bash
./bin/temp-monitor --duration 300 --interval 5
```

### Collect and display graph
```bash
./bin/temp-monitor --duration 60 --graph
```

### Custom output file location
```bash
./bin/temp-monitor --output ~/my-temps.csv --duration 120 --graph
```

### View stored data
```bash
cat ~/.cache/temp-data.csv
```

## Command-line Options

- `--duration <seconds>` - How long to collect data (default: 60)
- `--interval <seconds>` - Seconds between readings (default: 2)
- `--output <path>` - CSV file location (default: ~/.cache/temp-data.csv)
- `--graph` - Display ASCII graph after collection completes

## Output Format

The script stores data in CSV format with columns:
```
timestamp,cpu_temp,gpu_temp,max_temp
2024-07-11 14:30:45,65.5,N/A,65.5
2024-07-11 14:30:47,66.2,N/A,66.2
```

## Graph Example

```
2024-07-11 14:30:45: ████████████ 65.5°C
2024-07-11 14:30:47: ██████████████ 66.2°C
2024-07-11 14:30:49: ████████████████ 68.1°C

Min: 65.5°C | Max: 68.1°C | Range: 2.6°C
```

## Tips

- Run multiple instances with different `--output` files to track different time periods
- Use cron to collect continuous background data: `*/5 * * * * ~/nixos-setup/bin/temp-monitor --duration 1 --interval 1`
- High temperatures may indicate a need for thermal paste replacement or fan cleaning
- The graph is great for spotting thermal throttling or fan ramp-ups during workloads

## Troubleshooting

**No temperature readings (showing "N/A")**:
- Check if `sensors` is installed and working: `sensors`
- Check thermal zone: `cat /sys/class/thermal/thermal_zone0/temp`
- Run `sudo sensors-detect` to configure lm_sensors on first use

**Permission denied reading temperatures**:
- Some systems require sudo for detailed sensor access
- Try: `sudo ./bin/temp-monitor`

**CSV file grows too large**:
- Archive old data: `mv ~/.cache/temp-data.csv ~/.cache/temp-data-$(date +%s).csv`
- Or use `--output` with a date-stamped filename
