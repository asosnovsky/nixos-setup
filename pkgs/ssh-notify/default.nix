{ lib
, stdenvNoCC
, replaceVars
, makeWrapper
, nushell
, socat
, libnotify
}:

# Forwards `notify-send` calls made in an SSH session back to a notification
# daemon on the client desktop, instead of failing with
# `GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown` (no daemon exists on
# a headless host). Ties into `modules/nixos/common/ssh-notify.nix`, which
# wires up the `RemoteForward`/`SetEnv` plumbing that gives each concurrent
# SSH session its own per-connection socket on the server side.
#
# Three entry points, installed as separate binaries:
# - `notify-send`             -- server-side wrapper, shadows the real binary
# - `ssh-notify-listener`     -- client-side, one persistent listen socket
# - `ssh-notify-handle-connection` -- client-side, one JSON payload per call
#
# The actual socket I/O is delegated to `socat`; the nushell scripts own the
# typed payload encoding/decoding and control flow.

let
  realNotifySend = "${libnotify}/bin/notify-send";
in
stdenvNoCC.mkDerivation {
  pname = "ssh-notify";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    install -m755 ${replaceVars ./notify-send.nu {
      real_notify_send = realNotifySend;
    }} $out/bin/.notify-send-wrapped.nu

    install -m755 ${replaceVars ./ssh-notify-handle-connection.nu {
      real_notify_send = realNotifySend;
    }} $out/bin/ssh-notify-handle-connection.nu

    install -m755 ${replaceVars ./ssh-notify-listener.nu {
      handle_connection = "$out/bin/ssh-notify-handle-connection.nu";
    }} $out/bin/.ssh-notify-listener-wrapped.nu

    makeWrapper ${nushell}/bin/nu $out/bin/notify-send \
      --add-flags "$out/bin/.notify-send-wrapped.nu" \
      --prefix PATH : ${lib.makeBinPath [ socat ]}

    makeWrapper ${nushell}/bin/nu $out/bin/ssh-notify-listener \
      --add-flags "$out/bin/.ssh-notify-listener-wrapped.nu" \
      --prefix PATH : ${lib.makeBinPath [ socat nushell ]}

    chmod +x $out/bin/ssh-notify-handle-connection.nu

    runHook postInstall
  '';

  meta = {
    description = "Forwards notify-send from SSH sessions back to the client desktop, one socket per concurrent connection";
    homepage = "https://github.com/skykanin/nixos-setup";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = "notify-send";
  };
}
