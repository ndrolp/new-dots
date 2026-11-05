#!/usr/bin/env python3
"""The app menu's bridge to the menus apps export over D-Bus.

Run by services/AppMenuBridge.qml, which writes one JSON object per line on
stdin and reads one per line from stdout:

  in   {"focus": {"pid": 1234, "title": "Home - Nemo", "xwayland": true}}
       {"focus": null}                          no window focused
       {"activate": <action>}                   a dbusMenu or gtkAction action
  out  {"pid": 1234, "exported": <exported>}    the focused app's menus, or null
       {"log": "..."}                           one line for the Quickshell log

It finds the focused window's menus two ways, both only for XWayland windows
since only they export menus here:
  - com.canonical.AppMenu.Registrar: menus registered as DBusMenu
    (Electron, Java, Qt on X11), keyed by X11 window id;
  - the _GTK_* properties GTK apps set on their X11 windows when
    appmenu-gtk-module is loaded: an org.gtk.Menus menubar and its actions.
Hyprland doesn't tell X11 window ids, so a menu belongs to the focused window
when the D-Bus connection that exports it has the window's pid
(GetConnectionUnixProcessID); among several, the one whose X11 window has the
same title wins. What it hands over is raw; AppMenuModel.exportedMenus turns it
into menus.
"""

import json
import os
import shutil
import subprocess
import sys

try:
    from gi.repository import Gio, GLib
except ImportError:
    print(json.dumps({"log": "app menu: python-gobject is missing; showing the shell menus only"}), flush=True)
    sys.exit(0)

REGISTRAR = "com.canonical.AppMenu.Registrar"
REGISTRAR_PATH = "/com/canonical/AppMenu/Registrar"
DBUSMENU = "com.canonical.dbusmenu"
GTK_MENUS = "org.gtk.Menus"
GTK_ACTIONS = "org.gtk.Actions"
DBUSMENU_PROPERTIES = ["type", "label", "enabled", "visible", "children-display",
                       "toggle-type", "toggle-state"]
TIMEOUT = 2000

try:
    bus = Gio.bus_get_sync(Gio.BusType.SESSION)
except GLib.Error as bus_error:
    print(json.dumps({"log": "app menu: no session bus (" + bus_error.message + "); showing the shell menus only"}),
          flush=True)
    sys.exit(0)
focus = None
current = None          # the menu being followed: dict(kind, service, ...)
subscriptions = []
gtk_groups = []
logged = set()
pending = {}


def send(message):
    print(json.dumps(message, default=lambda value: None), flush=True)


def log_once(key, text):
    if key not in logged:
        logged.add(key)
        send({"log": "app menu: " + text})


def call(name, path, interface, method, args, reply):
    result = bus.call_sync(name, path, interface, method, args,
                           GLib.VariantType(reply) if reply else None,
                           Gio.DBusCallFlags.NONE, TIMEOUT, None)
    return result.unpack() if result is not None else None


def connection_pid(name):
    try:
        return call("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                    "GetConnectionUnixProcessID", GLib.Variant("(s)", (name,)), "(u)")[0]
    except GLib.Error:
        return None


def later(key, milliseconds, function):
    """Runs `function` once after `milliseconds`, folding repeated asks into one."""
    if key in pending:
        GLib.source_remove(pending.pop(key))

    def run():
        pending.pop(key, None)
        function()
        return False
    pending[key] = GLib.timeout_add(milliseconds, run)


# ---- X11 ----------------------------------------------------------------

def xprop(*args):
    if not os.environ.get("DISPLAY"):
        log_once("display", "no X11 display; XWayland apps' menus can't be found")
        return ""
    if not shutil.which("xprop"):
        log_once("xprop", "xprop is missing; GTK apps' menus can't be found")
        return ""
    try:
        return subprocess.run(["xprop", *args], capture_output=True, text=True, timeout=2).stdout
    except (OSError, subprocess.SubprocessError):
        return ""


def window_properties(window):
    """The X11 window's string and number properties, as { name: value }."""
    properties = {}
    for line in xprop("-id", str(window), "_NET_WM_NAME", "_NET_WM_PID", "_GTK_UNIQUE_BUS_NAME",
                      "_GTK_MENUBAR_OBJECT_PATH", "_GTK_APPLICATION_OBJECT_PATH",
                      "_GTK_WINDOW_OBJECT_PATH").splitlines():
        if " = " not in line:
            continue
        name, value = line.split(" = ", 1)
        name = name.split("(", 1)[0].strip()
        value = value.strip()
        if value.startswith('"') and value.endswith('"'):
            value = value[1:-1].replace('\\"', '"').replace("\\\\", "\\")
        properties[name] = value
    return properties


def x_windows():
    line = xprop("-root", "_NET_CLIENT_LIST")
    if "#" not in line:
        return []
    return [word.strip() for word in line.split("#", 1)[1].split(",") if word.strip()]


# ---- Finding the focused window's menu ---------------------------------

def registrar_menus(retry=True):
    try:
        return call(REGISTRAR, REGISTRAR_PATH, REGISTRAR, "GetMenus", None, "(a(uso))")[0]
    except GLib.Error as error:
        # The first call D-Bus-activates the registrar, which may not have
        # its object up yet.
        if retry and ("UnknownMethod" in str(error) or "UnknownObject" in str(error)):
            GLib.usleep(300000)
            return registrar_menus(False)
        log_once("registrar", "no AppMenu registrar (" + error.message + "); "
                 "DBusMenu apps show the shell menus only")
        return []


def candidates(pid):
    found = []
    for window, service, path in registrar_menus():
        if connection_pid(service) == pid:
            found.append({"kind": "dbusmenu", "service": service, "path": path, "window": window})
    for window in x_windows():
        properties = window_properties(window)
        service = properties.get("_GTK_UNIQUE_BUS_NAME")
        menu_path = properties.get("_GTK_MENUBAR_OBJECT_PATH")
        if not service or not menu_path:
            continue
        if connection_pid(service) != pid:
            continue
        action_paths = {"unity": menu_path}
        if properties.get("_GTK_APPLICATION_OBJECT_PATH"):
            action_paths["app"] = properties["_GTK_APPLICATION_OBJECT_PATH"]
        if properties.get("_GTK_WINDOW_OBJECT_PATH"):
            action_paths["win"] = properties["_GTK_WINDOW_OBJECT_PATH"]
        found.append({"kind": "gtk", "service": service, "menuPath": menu_path,
                      "actionPaths": action_paths, "title": properties.get("_NET_WM_NAME")})
    return found


def window_title(candidate):
    if "title" not in candidate:
        candidate["title"] = window_properties(candidate["window"]).get("_NET_WM_NAME")
    return candidate["title"]


def choose(found, title):
    if len(found) > 1:
        for candidate in found:
            if window_title(candidate) == title:
                return candidate
    return found[0] if found else None


# ---- Reading a menu -----------------------------------------------------

def dbusmenu_exported(menu):
    layout = call(menu["service"], menu["path"], DBUSMENU, "GetLayout",
                  GLib.Variant("(iias)", (0, -1, DBUSMENU_PROPERTIES)), "(u(ia{sv}av))")[1]
    # Some apps fill a submenu only when it's about to show.
    changed = False
    for child in layout[2]:
        try:
            changed = call(menu["service"], menu["path"], DBUSMENU, "AboutToShow",
                           GLib.Variant("(i)", (child[0],)), "(b)")[0] or changed
        except GLib.Error:
            pass
    if changed:
        layout = call(menu["service"], menu["path"], DBUSMENU, "GetLayout",
                      GLib.Variant("(iias)", (0, -1, DBUSMENU_PROPERTIES)), "(u(ia{sv}av))")[1]
    return {"kind": "dbusmenu", "service": menu["service"], "path": menu["path"], "layout": layout}


def gtk_exported(menu):
    global gtk_groups
    menus = []
    started = []
    wanted = [0]
    # Sections and submenus can live in other groups, which have to be
    # started too; this follows them all.
    while wanted and len(started) < 200:
        reply = call(menu["service"], menu["menuPath"], GTK_MENUS, "Start",
                     GLib.Variant("(au)", (wanted,)), "(a(uuaa{sv}))")[0]
        started += wanted
        wanted = []
        for group, number, items in reply:
            menus.append([group, number, items])
            for item in items:
                for link in (":section", ":submenu"):
                    if link in item and item[link][0] not in started and item[link][0] not in wanted:
                        wanted.append(item[link][0])
    gtk_groups = started
    actions = {}
    for prefix, path in menu["actionPaths"].items():
        try:
            described = call(menu["service"], path, GTK_ACTIONS, "DescribeAll", None, "(a{s(bgav)})")[0]
        except GLib.Error:
            continue
        for name, description in described.items():
            actions[prefix + "." + name] = list(description)
    return {"kind": "gtk", "service": menu["service"], "menuPath": menu["menuPath"],
            "actionPaths": menu["actionPaths"], "menus": menus, "actions": actions}


def unfollow():
    global current, gtk_groups
    for subscription in subscriptions:
        bus.signal_unsubscribe(subscription)
    subscriptions.clear()
    if current and current["kind"] == "gtk" and gtk_groups:
        try:
            call(current["service"], current["menuPath"], GTK_MENUS, "End",
                 GLib.Variant("(au)", (gtk_groups,)), None)
        except GLib.Error:
            pass
    gtk_groups = []
    current = None


def follow(menu):
    global current
    current = menu

    def changed(*_):
        later("refresh", 150, publish)
    if menu["kind"] == "dbusmenu":
        for signal in ("LayoutUpdated", "ItemsPropertiesUpdated"):
            subscriptions.append(bus.signal_subscribe(menu["service"], DBUSMENU, signal, menu["path"],
                                                      None, Gio.DBusSignalFlags.NONE, changed))
    else:
        subscriptions.append(bus.signal_subscribe(menu["service"], GTK_MENUS, "Changed", menu["menuPath"],
                                                  None, Gio.DBusSignalFlags.NONE, changed))
        for path in set(menu["actionPaths"].values()):
            subscriptions.append(bus.signal_subscribe(menu["service"], GTK_ACTIONS, "Changed", path,
                                                      None, Gio.DBusSignalFlags.NONE, changed))


def publish():
    if focus is None:
        return
    exported = None
    if current is not None:
        try:
            exported = dbusmenu_exported(current) if current["kind"] == "dbusmenu" else gtk_exported(current)
        except GLib.Error as error:
            log_once("read:" + current["service"], "couldn't read " + current["service"] + "'s menu ("
                     + error.message + ")")
    send({"pid": focus["pid"], "exported": exported})


def resolve(retry=True):
    unfollow()
    if focus is None:
        return
    if not focus.get("xwayland"):
        send({"pid": focus["pid"], "exported": None})
        return
    menu = choose(candidates(focus["pid"]), focus.get("title"))
    if menu is not None:
        follow(menu)
    elif retry:
        # A window that just opened may set its menu a moment later.
        later("resolve", 1000, lambda: resolve(False))
    publish()


# ---- Running items ------------------------------------------------------

def activate(action):
    try:
        if action.get("kind") == "dbusMenu":
            call(action["service"], action["path"], DBUSMENU, "Event",
                 GLib.Variant("(isvu)", (int(action["itemId"]), "clicked", GLib.Variant("i", 0), 0)), None)
        elif action.get("kind") == "gtkAction":
            parameters = []
            if "target" in action:
                parameters.append(GLib.Variant(action.get("targetType") or "s", action["target"]))
            call(action["service"], action["path"], GTK_ACTIONS, "Activate",
                 GLib.Variant("(sava{sv})", (action["name"], parameters, {})), None)
    except (GLib.Error, KeyError, TypeError, ValueError) as error:
        send({"log": "app menu: couldn't run a menu item (" + str(error) + ")"})


# ---- Input --------------------------------------------------------------

def handle(line):
    global focus
    try:
        message = json.loads(line)
    except ValueError:
        return
    if "focus" in message:
        focus = message["focus"]
        later("resolve", 50, resolve)
    elif "activate" in message and isinstance(message["activate"], dict):
        activate(message["activate"])


def registrar_changed(*_):
    later("resolve", 150, resolve)


buffered = b""


def read_input(fd, condition):
    global buffered
    chunk = os.read(fd, 65536) if condition & GLib.IO_IN else b""
    if not chunk:
        loop.quit()
        return False
    buffered += chunk
    *lines, buffered = buffered.split(b"\n")
    for line in lines:
        handle(line.decode("utf-8", "replace"))
    return True


for registrar_signal in ("WindowRegistered", "WindowUnregistered"):
    bus.signal_subscribe(REGISTRAR, REGISTRAR, registrar_signal, REGISTRAR_PATH, None,
                         Gio.DBusSignalFlags.NONE, registrar_changed)

loop = GLib.MainLoop()
GLib.io_add_watch(0, GLib.PRIORITY_DEFAULT, GLib.IO_IN | GLib.IO_HUP | GLib.IO_ERR, read_input)
loop.run()
