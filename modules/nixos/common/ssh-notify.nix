{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.common.ssh-notify;

  # Client-side listen socket. Fixed/shared is fine here: socat's `fork`
  # mode accepts unbounded connections over this path's lifetime, one per
  # `notify-send` call from any concurrently forwarded SSH session.
  #
  # NOTE: assumes a single interactive uid (1000) on the desktop host, same
  # as the rest of this single-user setup.
  localSocketPath = "/run/user/1000/ssh-notify/listener.sock";

  # Remote-side (server) forwarded socket. Uses OpenSSH's %C token (hash of
  # local host/port/user + remote host/port/user, requires OpenSSH >= 8.9)
  # so each concurrent SSH connection gets its own bind path on the server —
  # this is what the old shared /tmp/ssh-notify.sock path got wrong: only
  # one concurrent session could ever bind it, and every other session's
  # `RemoteForward` silently failed ("remote port forwarding failed for
  # listen path ..."), falling back to a broken direct D-Bus notify-send.
  remoteSocketPath = "/tmp/ssh-notify-%C.sock";

  # Detect if this host is acting as the notification client (the machine you sit in front of)
  isClient =
    cfg.role == "client"
    || (cfg.role == "auto" && (config.skyg.nixos.desktop.enable or false));

  isServer =
    cfg.role == "server"
    || (cfg.role == "auto" && !isClient);
in
{
  options.skyg.nixos.common.ssh-notify = {
    enable = lib.mkEnableOption
      "forward libnotify messages from SSH sessions back to the client desktop (prefixed with hostname)";

    role = lib.mkOption {
      type = lib.types.enum [ "auto" "client" "server" ];
      default = "auto";
      description = ''
        auto  = client on hosts with skyg.nixos.desktop.enable, server otherwise
        client = force desktop listener + RemoteForward
        server = force wrapper only
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # hiPrio: desktop hosts (e.g. hl-fwdesk) also pull in the real libnotify
    # via the tiler module's "always-on plumbing" packages, and both provide
    # bin/notify-send. Force ours to win that collision unconditionally.
    environment.systemPackages = [ (lib.hiPrio pkgs.ssh-notify) ];

    # Client: ask SSH to forward this connection's notification socket back
    # to the shared local listener, and tell the server-side wrapper (via
    # SetEnv, expanded here with the same %C the RemoteForward bind uses)
    # which socket to connect to.
    # Scoped to lab hosts: without the Match, every outbound ssh (GitHub,
    # work bastions, …) tries the forward, logs failures, and may leave a
    # socket behind on hosts that accept it.
    programs.ssh.extraConfig = lib.mkIf isClient ''
      Match host *.lab.internal
        RemoteForward ${remoteSocketPath} ${localSocketPath}
        SetEnv SSH_NOTIFY_SOCK=${remoteSocketPath}
    '';

    # Server: accept the SSH_NOTIFY_SOCK env var forwarded by the client
    # above (SSH only passes through an allow-listed set by default).
    services.openssh.settings.AcceptEnv = lib.mkIf isServer [ "SSH_NOTIFY_SOCK" ];

    # %C is a deterministic hash of (local host, remote user, remote host,
    # remote port) -- the same value every time you connect to this host
    # from this client, not a per-connection nonce. Without this, a socket
    # left behind by an abnormally-ended session (network drop, kill) blocks
    # every subsequent connection to the same host with "remote port
    # forwarding failed for listen path ...". Tell sshd to unlink and rebind
    # instead of refusing.
    services.openssh.settings.StreamLocalBindUnlink = lib.mkIf isServer true;

    # Client listener: one persistent socket, forked per connection, that
    # turns each incoming JSON payload into a real local notification.
    systemd.user.services.ssh-notify-listener = lib.mkIf isClient {
      description = "Receive notify-send from remote hosts over SSH and display locally";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.ssh-notify}/bin/ssh-notify-listener";
        Restart = "always";
        RestartSec = 2;
      };
    };

    # On servers we rely purely on the wrapper; no extra services needed.
  };
}
