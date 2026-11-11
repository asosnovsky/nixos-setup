# diagnix: a read-only user nbot logs in as to diagnose a host.
# Sees logs, units, /proc and /nix/store; can't change the system.
{ config, lib, pkgs, options, ... }:
let
  cfg = config.skyg.nixos.common.diagnix;
  data = import ./hosts.nix;
  uid = 2950;

  # This host runs nbot, so its own containers connect from random private IPs.
  hasNbot = options.services ? nbot && config.services.nbot.enable;

  keyLine = from: ''restrict,pty,from="${from}" ${cfg.publicKey}'';

  runtime =
    if config.virtualisation.docker.enable then "${config.virtualisation.docker.package}/bin/docker"
    else if config.virtualisation.podman.enable then "${config.virtualisation.podman.package}/bin/podman"
    else null;
  rt = toString runtime;

  # Fixed root scripts diagnix may run with sudo. Anything taking input checks it.
  script = name: inputs: text: pkgs.writeShellApplication {
    inherit name text;
    runtimeInputs = inputs;
  };
  scripts = [
    (script "diag-smart" [ pkgs.smartmontools pkgs.nvme-cli ] ''
      smartctl --scan | while read -r dev _; do
        echo "=== $dev"; smartctl -a "$dev" || true
      done
      for dev in /dev/nvme[0-9]; do
        [ -e "$dev" ] || continue
        echo "=== $dev"; nvme smart-log "$dev" || true
      done
    '')
    (script "diag-ports" [ pkgs.iproute2 ] "ss -tulpn")
    (script "diag-firewall" [ pkgs.iptables pkgs.nftables ] ''
      iptables -S || true; iptables -t nat -S || true; ip6tables -S || true
      nft list ruleset || true
    '')
    (script "diag-btrfs" [ pkgs.btrfs-progs pkgs.util-linux ] ''
      findmnt -rn -t btrfs -o TARGET | sort -u | while read -r mnt; do
        echo "=== $mnt"; btrfs filesystem usage "$mnt" || true; btrfs device stats "$mnt" || true
      done
    '')
    (script "diag-io" [ pkgs.iotop ] "iotop -b -o -n 3 -d 1")
  ] ++ lib.optionals (runtime != null) [
    (script "diag-docker-ps" [ ] ''
      ${rt} ps -a; ${rt} stats --no-stream; ${rt} system df
    '')
    (script "diag-docker-logs" [ ] ''
      if [ $# -ne 1 ] || ! [[ "$1" =~ ^[A-Za-z0-9][A-Za-z0-9_.-]*$ ]]; then
        echo "usage: diag-docker-logs <container-name>" >&2; exit 2
      fi
      ${rt} logs --tail 500 "$1" 2>&1
    '')
  ];
in
{
  options.skyg.nixos.common.diagnix = {
    enable = lib.mkEnableOption "the read-only diagnix user for nbot";
    publicKey = lib.mkOption {
      type = lib.types.str;
      default = data.publicKey;
      description = "nbot's client public key for diagnix.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups.diagnix.gid = uid;
    users.users.diagnix = {
      inherit uid;
      isNormalUser = true;
      group = "diagnix";
      description = "nbot read-only diagnostics";
      shell = pkgs.bash;
      extraGroups = [ "systemd-journal" ];
      openssh.authorizedKeys.keys =
        [ (keyLine (lib.concatStringsSep "," data.nbotHosts)) ]
        # Containers on this host: any private IP outside the LAN.
        ++ lib.optional hasNbot (keyLine "!${data.lanSubnet},10.0.0.0/8,172.16.0.0/12,192.168.0.0/16");
    };

    # A runaway command can't starve the host.
    systemd.slices."user-${toString uid}" = {
      overrideStrategy = "asDropin";
      sliceConfig = { MemoryMax = "1G"; CPUQuota = "100%"; TasksMax = 256; };
    };

    security.sudo.extraRules = [{
      users = [ "diagnix" ];
      commands = map (s: { command = lib.getExe s; options = [ "NOPASSWD" ]; }) scripts;
    }];

    programs.mtr.enable = true;
    environment.systemPackages = scripts ++ (with pkgs; [
      lsof
      pciutils
      usbutils
      dnsutils
      sysstat
      ethtool
      lm_sensors
      htop
    ]);

    # nbot drops all container traffic to the host except a few ports; let SSH in too.
    networking.firewall = lib.mkIf (hasNbot && !config.networking.nftables.enable) {
      extraCommands = lib.mkAfter ''
        iptables -C INPUT -i ve-+ -p tcp --dport 22 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -i ve-+ -p tcp --dport 22 -j ACCEPT
      '';
      extraStopCommands = ''
        iptables -D INPUT -i ve-+ -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
      '';
    };
  };
}
