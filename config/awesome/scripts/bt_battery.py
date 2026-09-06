#!/usr/bin/env python3
# Consulta la batería de dispositivos Bluetooth conectados vía D-Bus
# (org.bluez.Battery1, requiere Experimental = true en /etc/bluetooth/main.conf).
# Imprime una línea por dispositivo conectado con nivel: "Nombre|pct".
import sys

try:
    import dbus
except ImportError:
    sys.exit(0)


def main():
    bus = dbus.SystemBus()
    try:
        mgr = dbus.Interface(
            bus.get_object("org.bluez", "/"), "org.freedesktop.DBus.ObjectManager"
        )
        objs = mgr.GetManagedObjects()
    except dbus.exceptions.DBusException:
        sys.exit(0)

    for path, ifaces in objs.items():
        dev = ifaces.get("org.bluez.Device1")
        if not dev:
            continue
        if not dev.get("Connected", False):
            continue
        battery = ifaces.get("org.bluez.Battery1")
        if not battery:
            continue
        pct = battery.get("Percentage")
        if pct is None:
            continue
        name = dev.get("Name") or dev.get("Alias") or ""
        print("%s|%d" % (name, int(pct)))


if __name__ == "__main__":
    main()