#!/usr/bin/python3
"""Print one line per mouse-button press: "<button> <x> <y>" in global logical
coordinates. Reads only button-down events from pointer devices (needs the
`input` group and python-evdev); keyboard devices are never opened. The pointer
position comes from Hyprland's socket, so nothing about movement is recorded.
Devices are rescanned every few seconds to pick up hotplugged mice."""
import json
import os
import select
import socket
import sys
import time

try:
    import evdev
    from evdev import ecodes
except ImportError:
    print("starwatch-clicks: python-evdev is missing (sudo pacman -S python-evdev)", file=sys.stderr)
    sys.exit(3)

BUTTONS = {ecodes.BTN_LEFT: "L", ecodes.BTN_RIGHT: "R", ecodes.BTN_MIDDLE: "M"}
SOCK = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/run/user/%d" % os.getuid()), "hypr",
                    os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", ""), ".socket.sock")


def cursor():
    try:
        with socket.socket(socket.AF_UNIX) as s:
            s.settimeout(0.2)
            s.connect(SOCK)
            s.sendall(b"j/cursorpos")
            data = b""
            while chunk := s.recv(4096):
                data += chunk
        pos = json.loads(data)
        return int(pos["x"]), int(pos["y"])
    except (OSError, ValueError, KeyError):
        return None


def pointers():
    found = {}
    for path in evdev.list_devices():
        try:
            dev = evdev.InputDevice(path)
            keys = dev.capabilities().get(ecodes.EV_KEY, [])
            if ecodes.BTN_LEFT in keys and ecodes.KEY_A not in keys:
                found[dev.fd] = dev
            else:
                dev.close()
        except OSError:
            pass
    return found


def main():
    devices = pointers()
    if not devices:
        print("starwatch-clicks: no readable mouse; add yourself to the input group "
              "(sudo usermod -aG input $USER) and log in again", file=sys.stderr, flush=True)
    rescan = time.monotonic() + 5
    while True:
        if time.monotonic() > rescan:
            for dev in devices.values():
                dev.close()
            devices = pointers()
            rescan = time.monotonic() + 5
        ready, _, _ = select.select(list(devices), [], [], 1.0)
        for fd in ready:
            try:
                for ev in devices[fd].read():
                    if ev.type == ecodes.EV_KEY and ev.value == 1 and ev.code in BUTTONS:
                        pos = cursor()
                        if pos:
                            print(BUTTONS[ev.code], *pos, flush=True)
            except OSError:
                rescan = 0


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
