# robotnix network: one routed virtual switch, per-robot firewall and DNS.
#
# Robots plug into the switch bridge and hold their LAN IP as a /32. The host
# routes to them and answers ARP for their IPs on the uplink (proxy ARP), so
# every packet passes the host firewall. Robots never see the host's netns.
{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.server.robotnix;
  h = import ./helpers.nix { inherit config lib; };
  rs = h.robotList;
  br = cfg.switch.name;
  sw = cfg.switch.address;

  set = xs: "{ ${lib.concatStringsSep ", " xs} }";

  # Never reachable, whatever the tier says.
  neverRanges = [
    "0.0.0.0/8"
    "127.0.0.0/8"
    "224.0.0.0/4"
    "240.0.0.0/4"
  ];
  # Private ranges: only via lanAccess / allowLan.
  lanRanges = [
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "169.254.0.0/16"
    "100.64.0.0/10"
  ];

  # Outbound (forwarded) traffic from one robot. Order matters.
  outChain =
    r:
    let
      a = r.access;
    in
    ''
      chain out_${r.nft} {
        # DNS only via the host (port 53 is redirected in prerouting).
        meta l4proto { tcp, udp } th dport 853 drop
        meta l4proto { tcp, udp } th dport 53 drop
        # The redirected DNS request (now dport = the robot's dnsmasq port)
        # must pass before the private-range drop.
        ip daddr ${sw} meta l4proto { tcp, udp } th dport ${toString r.dnsPort} accept
        ip daddr ${set neverRanges} drop
    ''
    + lib.optionalString (a.blockedCidrs != [ ]) ''
      ip daddr ${set a.blockedCidrs} drop
    ''
    + lib.concatMapStrings
      (e: ''
        ip daddr ${e.address} ${e.proto} dport ${toString e.port} accept
      '')
      a.lanAccess
    + (
      if a.allowLan then
        ''
          ip daddr ${set lanRanges} accept
        ''
      else
        ''
          ip daddr ${set lanRanges} drop
        ''
    )
    + (
      if a.internet == "all" then
        ''
          accept
        ''
      else
        lib.optionalString (a.allowedCidrs != [ ]) ''
          ip daddr ${set a.allowedCidrs} accept
        ''
        + ''
          ip daddr @allow_${r.nft} accept
          drop
        ''
    )
    + ''
      }
    '';

  # Traffic from one robot to the host itself.
  inChain = r: ''
    chain in_${r.nft} {
      meta l4proto { tcp, udp } th dport ${toString r.dnsPort} accept
      icmp type echo-request accept
  ''
  + lib.concatMapStrings
    (p: ''
      ${p.proto} dport ${toString p.port} accept
    '')
    r.access.hostAccess
  + ''
      drop
    }
  '';

  vmap = prefix: set (map (r: "${r.address} : jump ${prefix}_${r.nft}") rs);

  # Every robot's own address.
  robotIps = set (map (r: r.address) rs);

  # Host-side dnsmasq per robot. It is the robot's only resolver.
  dnsConf =
    r:
    let
      a = r.access;
      servers = d: lib.concatMapStrings (u: "server=/${d}/${u}\n") cfg.dnsUpstreams;
    in
    pkgs.writeText "robotnix-${r.name}-dnsmasq.conf" (
      ''
        listen-address=${sw}
        port=${toString r.dnsPort}
        bind-dynamic
        no-resolv
        no-hosts
        no-poll
        domain-needed
        bogus-priv
        user=root
        cache-size=1000
        # Short TTLs so allowlist IP sets stay fresh after a host reload.
        max-ttl=300
        max-cache-ttl=300
      ''
      + lib.concatMapStrings servers cfg.localDomains
      + (
        if a.internet == "all" then
          lib.concatMapStrings (u: "server=${u}\n") cfg.dnsUpstreams
        else
          ''
            # Allowlist: everything else is NXDOMAIN.
            address=/#/
          ''
          + lib.concatMapStrings
            (
              d: servers d + "nftset=/${d}/4#inet#robotnix#allow_${r.nft}\n"
            )
            a.allowedDomains
      )
      + lib.concatMapStrings (d: "address=/${d}/\n") a.blockedDomains
    );
in
lib.mkIf cfg.enable {
  # Same keys and priority networking.nat (and hermenix) use.
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = lib.mkOverride 99 true;
    "net.ipv4.conf.default.forwarding" = lib.mkOverride 99 true;
  };

  # ---------------------------------------------------------------- switch
  systemd.network.enable = true;
  systemd.network.netdevs."40-${br}".netdevConfig = {
    Kind = "bridge";
    Name = br;
  };
  systemd.network.networks."40-${br}" = {
    matchConfig.Name = br;
    address = [ "${sw}/${toString cfg.switch.prefixLength}" ];
    routes = map
      (r: {
        Destination = "${r.address}/32";
        Scope = "link";
      })
      rs;
    networkConfig = {
      ConfigureWithoutCarrier = true;
      LinkLocalAddressing = "no";
      IPv6AcceptRA = false;
    };
    linkConfig.RequiredForOnline = "no";
  };
  # Robot ports (nspawn names them vb-<robot>). Isolated: robots can't talk
  # to each other at L2, only through the host's rules.
  systemd.network.networks."41-${br}-ports" = lib.mkIf (rs != [ ]) {
    matchConfig.Name = lib.concatMapStringsSep " " (r: r.port) rs;
    networkConfig = {
      Bridge = br;
      LinkLocalAddressing = "no";
    };
    bridgeConfig.Isolated = true;
    linkConfig.RequiredForOnline = "no";
  };
  networking.networkmanager.unmanaged = [ "interface-name:${br}" ] ++ map (r: "interface-name:${r.port}") rs;

  # -------------------------------------------------------------- firewall
  networking.nftables.enable = true;

  # L2: each port may only speak IPv4/ARP from its own address.
  networking.nftables.tables.robotnix-bridge = lib.mkIf (rs != [ ]) {
    family = "bridge";
    content = ''
      chain prerouting {
        type filter hook prerouting priority filter; policy accept;
    ''
    + lib.concatMapStrings
      (r: ''
        iifname "${r.port}" ether type != { ip, arp } drop
        iifname "${r.port}" ip saddr != ${r.address} drop
        iifname "${r.port}" arp saddr ip != ${r.address} drop
      '')
      rs
    + ''
      }
    '';
  };

  # L3. Runs before nixos-fw, so a drop here is final no matter what other
  # modules accept. Source addresses are trusted thanks to the bridge table.
  networking.nftables.tables.robotnix = lib.mkIf (rs != [ ]) {
    family = "inet";
    content = ''
      ${lib.concatMapStrings (r: ''
        set allow_${r.nft} { type ipv4_addr; }
      '') rs}

      chain prerouting {
        type nat hook prerouting priority dstnat; policy accept;
      ${lib.concatMapStrings (r: ''
        iifname "${br}" ip saddr ${r.address} meta l4proto { tcp, udp } th dport 53 dnat ip to ${sw}:${toString r.dnsPort}
      '') rs}
      }

      chain forward {
        type filter hook forward priority filter - 10; policy accept;
        # Traffic meant for a robot goes to that robot, nowhere else (e.g.
        # another module's DNAT). Replies are not touched.
        ct direction original ct original ip daddr ${robotIps} oifname != "${br}" drop
        iifname "${br}" ct state established,related accept
        iifname "${br}" meta nfproto ipv6 drop
        oifname "${br}" meta nfproto ipv6 drop
        # A robot's own connection that someone redirected elsewhere.
        iifname "${br}" ct status dnat drop
        iifname "${br}" ip saddr vmap ${vmap "out"}
        iifname "${br}" drop
        # Inbound from the LAN to robots: open.
      }

      chain input {
        type filter hook input priority filter - 10; policy accept;
        # Traffic meant for a robot, redirected to the host itself.
        ct direction original ct original ip daddr ${robotIps} drop
        iifname != "${br}" accept
        ct state established,related accept
        meta nfproto ipv6 drop
        ip saddr vmap ${vmap "in"}
        drop
      }

      ${lib.concatMapStrings outChain rs}
      ${lib.concatMapStrings inChain rs}
    '';
  };

  # The robotnix table already filtered; let nixos-fw pass the rest.
  networking.firewall.extraInputRules = ''
    iifname "${br}" accept
  '';
  networking.firewall.extraForwardRules = ''
    iifname "${br}" accept
    oifname "${br}" accept
  '';

  # ------------------------------------------------------------------- DNS
  systemd.services = lib.listToAttrs (
    map
      (
        r:
        lib.nameValuePair "${r.unit}-dns" {
          description = "robotnix DNS for ${r.name}";
          wantedBy = [ "multi-user.target" ];
          after = [
            "network.target"
            "nftables.service"
          ];
          serviceConfig = {
            ExecStart = "${pkgs.dnsmasq}/bin/dnsmasq --keep-in-foreground --pid-file --conf-file=${dnsConf r}";
            Restart = "always";
            RestartSec = 2;
            # Root only for nftset; everything else is locked down.
            CapabilityBoundingSet = [
              "CAP_NET_ADMIN"
              "CAP_NET_BIND_SERVICE"
              "CAP_NET_RAW"
              "CAP_SETUID"
              "CAP_SETGID"
            ];
            ProtectSystem = "strict";
            ProtectHome = true;
            PrivateTmp = true;
            PrivateDevices = true;
            NoNewPrivileges = true;
          };
        }
      )
      rs
  );
}
