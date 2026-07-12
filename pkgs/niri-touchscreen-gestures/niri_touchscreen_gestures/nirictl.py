import json
import os
import select
import socket
from contextlib import contextmanager
from typing import Any, Literal, TypeAlias

SupportedActions: TypeAlias = Literal[
    "FocusWorkspaceUp",
    "FocusWorkspaceDown",
    "FocusColumnLeft",
    "FocusColumnRight",
    "ToggleOverview",
]


def get_socket_path():
    """Get the Niri socket path from the environment, raising if not set."""
    socket_path = os.environ.get("NIRI_SOCKET")
    if not socket_path:
        raise RuntimeError("Niri is not running or NIRI_SOCKET is not set.")

    return socket_path


@contextmanager
def niri_socket():
    """Context manager for the Niri socket."""
    socket_path = get_socket_path()
    s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    s.connect(socket_path)
    s.setblocking(False)
    try:
        yield s
    finally:
        s.close()


def send_niri_command(command: dict[str, Any]) -> dict[str, Any]:
    """Send a raw JSON command to Niri and return the parsed reply."""
    with niri_socket() as s:
        s.sendall((json.dumps(command) + "\n").encode("utf-8"))

        # wait for data (up to 5 s)
        ready, _, _ = select.select([s], [], [], 5)
        if not ready:
            raise TimeoutError("No response from Niri")

        # read everything available
        data = bytearray()
        while True:
            try:
                chunk = s.recv(4096)
                if chunk:
                    data += chunk
                else:
                    break
            except BlockingIOError:
                break

        return json.loads(data.decode("utf-8"))


def send_niri_action(action: SupportedActions) -> bool:
    """Send an Action command"""
    request = {"Action": {action: {}}}
    reply = send_niri_command(request)
    return reply.get("Ok", "Handled").lower() == "handled"
