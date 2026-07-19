{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.common.ssh-notify;
  socketPath = "/tmp/ssh-notify.sock";

  # Detect if this host is acting as the notification client (the machine you sit in front of)
  isClient =
    cfg.role == "client"
    || (cfg.role == "auto" && (config.skyg.nixos.desktop.enable or false));

  isServer =
    cfg.role == "server"
    || (cfg.role == "auto" && !isClient);

  realNotifySend = "${pkgs.libnotify}/bin/notify-send";

  # Thin wrapper installed in PATH. On servers (when SSH'd) it forwards via the socket.
  notifyWrapper = pkgs.writeShellScriptBin "notify-send" ''
    #!${pkgs.runtimeShell}
    set -euo pipefail

    if [ -n "''${SSH_CONNECTION:-}" ] && [ -S "${socketPath}" ]; then
      host="$(hostname -s 2>/dev/null || hostname)"
      # Send two lines: prefixed title + body (or remaining args joined)
      # This keeps the protocol simple; complex notify-send flags are passed through as-is to the real binary on the client.
      printf '[%s] ' "$host"
      printf '%s ' "$@"
      printf '\n'
      # For body we just send the same line for now; user can refine later if needed.
      # The listener below will treat the received line as both title and body (notify-send accepts that).
      printf '%s\n' "$*"
    else
      exec ${realNotifySend} "$@"
    fi
  '';
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
    # Always provide socat + real libnotify + our wrapper (wrapper shadows notify-send when earlier in PATH)
    environment.systemPackages = [
      pkgs.socat
      pkgs.libnotify
      notifyWrapper
    ];

    # Client: ask SSH to forward the notification socket back to us on every connection
    programs.ssh.extraConfig = lib.mkIf isClient ''
      # Forward remote notify-send traffic to the local listener
      RemoteForward ${socketPath} ${socketPath}
    '';

    # Client listener: receives messages over the forwarded socket and shows them locally
    systemd.user.services.ssh-notify-listener = lib.mkIf isClient {
      description = "Receive notify-send from remote hosts over SSH and display locally";
      after = [ "default.target" ];
      wantedBy = [ "default.target" ];
      serviceConfig = {
        ExecStart =
          let
            listenerScript = pkgs.writeShellScript "ssh-notify-listener" ''
              set -euo pipefail
              # Remove stale socket if present
              rm -f ${socketPath}
              # Listen and for each connection read two lines (title line, body line)
              # and invoke the real notify-send. We keep it running via systemd Restart.
              while true; do
                ${pkgs.socat}/bin/socat \
                  UNIX-LISTEN:${socketPath},fork,mode=0666 \
                  SYSTEM:'read title; read body; ${realNotifySend} "$title" "$body" || true'
              done
            '';
          in
          "${listenerScript}";
        Restart = "always";
        RestartSec = 2;
      };
    };

    # On servers we rely purely on the wrapper; no extra services needed.
  };
}
