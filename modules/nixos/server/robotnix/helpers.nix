# Shared values for network.nix, robots.nix and the CLI.
{ config, lib }:
let
  cfg = config.skyg.nixos.server.robotnix;

  # "16G" -> bytes (IEC, same as systemd and truncate).
  toBytes =
    s:
    let
      m = builtins.match "([0-9]+)([KMGT])" s;
      mult = {
        K = 1024;
        M = 1024 * 1024;
        G = 1024 * 1024 * 1024;
        T = 1024 * 1024 * 1024 * 1024;
      };
    in
    lib.toInt (builtins.elemAt m 0) * mult.${builtins.elemAt m 1};

  # nft identifiers can't hold "-".
  nftName = name: lib.replaceStrings [ "-" ] [ "_" ] name;

  # Render a string as a Nix string literal (for generated .nix files).
  nixStr = s: lib.replaceStrings [ "\${" ] [ "\\\${" ] (builtins.toJSON s);

  # Shared tier + the robot's own tier. Lists are merged, the robot's
  # `internet` mode wins when set.
  mergeAccess =
    r:
    let
      s = cfg.access.shared;
      both = f: lib.unique (f s ++ f r);
    in
    {
      internet =
        if r.internet != null then
          r.internet
        else if s.internet != null then
          s.internet
        else
          "all";
      allowLan = s.allowLan || r.allowLan;
      allowedDomains = both (t: t.allowedDomains);
      allowedCidrs = both (t: t.allowedCidrs);
      blockedDomains = both (t: t.blockedDomains);
      blockedCidrs = both (t: t.blockedCidrs);
      lanAccess = both (t: t.lanAccess);
      hostAccess = both (t: t.hostAccess);
    };

  # Hermes's home inside a robot (the upstream module's default).
  hermesHome = "/var/lib/hermes/.hermes";

  # Shared Hermes block + the robot's own. Robot settings win.
  mergeHermes =
    r:
    let
      s = cfg.hermes;
      pick = a: b: if a != null then a else b;
      # Robot values that are null follow the shared ones.
      follow = what: lib.mapAttrs (k: v: pick r.${what}.${k} v) s.${what};
    in
    {
      enable = pick r.enable s.enable;
      inherit (r) name;
      settings = lib.recursiveUpdate s.settings r.settings;
      environmentFiles = lib.unique (s.environmentFiles ++ r.environmentFiles);
      gateway = follow "gateway";
      dashboard = follow "dashboard";
    };

  mkRobot = name: r:
    let
      hermes = mergeHermes r.hermes;
    in
    {
      inherit name hermes;
      inherit (r)
        id
        address
        autoStart
        privateUsers
        cpus
        memory
        disk
        snapshots
        seed
        user
        authorizedKeys
        git
        allowDocker
        allowTun
        ephemeral
        ;
      # Ephemeral + Hermes: keep only its cron jobs, memories and skills.
      persist =
        r.persist
        ++ lib.optionals (r.ephemeral && hermes.enable) (
          map (d: "${hermesHome}/${d}") [
            "cron"
            "memories"
            "skills"
          ]
        );
      nft = nftName name;
      port = "vb-${name}";
      dnsPort = 5300 + r.id;
      base = "${cfg.baseDir}/${name}";
      run = "/run/robotnix/${name}";
      unit = "robotnix-${name}";
      access = mergeAccess r.access;
    };

  robots = lib.mapAttrs mkRobot cfg.robots;
in
{
  inherit
    toBytes
    nftName
    nixStr
    robots
    hermesHome
    ;
  robotList = lib.attrValues robots;
}
