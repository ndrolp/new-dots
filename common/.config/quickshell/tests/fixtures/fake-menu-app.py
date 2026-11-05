#!/usr/bin/env python3
"""A stand-in for a native Wayland GTK3 app, for tests/app-menu-bridge.sh: it
exports menus on the session bus the way one does, with no display.

Usage: fake-menu-app.py <scenario> <file>
Touches <file> once it's on the bus; an activated action's name is appended
to <file>.
"""

import sys

from gi.repository import Gio, GLib

scenario, signal_file = sys.argv[1:3]
bus = Gio.bus_get_sync(Gio.BusType.SESSION)


def actions(*names):
    group = Gio.SimpleActionGroup()
    for name in names:
        action = Gio.SimpleAction.new(name, None)

        def activated(action, _parameter):
            with open(signal_file, "a") as out:
                out.write(action.get_name() + "\n")
        action.connect("activate", activated)
        group.add_action(action)
    return group


def menubar(title, *items):
    """A menubar with one menu, wrapped in a section like the real ones."""
    menu = Gio.Menu()
    for label, action in items:
        menu.append(label, action)
    root = Gio.Menu()
    root.append_submenu(title, menu)
    bar = Gio.Menu()
    bar.append_section(None, root)
    return bar


def module_window(number, menu):
    """What appmenu-gtk-module exports for a window's GtkMenuBar."""
    path = "/org/appmenu/gtk/window/menus/menubar/" + str(number)
    bus.export_menu_model(path, menu)
    bus.export_action_group(path, actions("Open"))


def application(*windows):
    """What GTK exports for a GtkApplication with a menubar."""
    bus.export_menu_model("/org/example/Fake/menus/menubar",
                          menubar("File", ("Close", "win.close"), ("About", "app.about")))
    bus.export_action_group("/org/example/Fake", actions("about"))
    for number in windows:
        bus.export_action_group("/org/example/Fake/window/" + str(number), actions("close"))


def silent_connection():
    """A second connection that never answers, like the one GTK apps keep."""
    address = Gio.dbus_address_get_for_bus_sync(Gio.BusType.SESSION, None)
    connection = Gio.DBusConnection.new_for_address_sync(
        address,
        Gio.DBusConnectionFlags.AUTHENTICATION_CLIENT | Gio.DBusConnectionFlags.MESSAGE_BUS_CONNECTION,
        None, None)
    connection.add_filter(lambda _connection, message, incoming: None if incoming else message)
    return connection


if scenario == "menubar":
    module_window(0, menubar("File", ("Open", "unity.Open")))
elif scenario == "application":
    application(1)
elif scenario == "hidden-menubar":
    # A window whose menubar is hidden exports it empty, as Nemo does by default.
    module_window(1, Gio.Menu())
    bus.export_menu_model("/org/example/Fake/menus/menubar", Gio.Menu())
elif scenario == "two-windows":
    module_window(0, menubar("File", ("Open", "unity.Open")))
    module_window(1, menubar("File", ("Open", "unity.Open")))
elif scenario == "two-application-windows":
    application(1, 2)
elif scenario == "silent-connection":
    silent = silent_connection()
    module_window(0, menubar("File", ("Open", "unity.Open")))
elif scenario != "no-menus":
    sys.exit("unknown scenario: " + scenario)

open(signal_file, "w").close()
GLib.MainLoop().run()
