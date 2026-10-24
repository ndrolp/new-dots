.pragma library

// Image sources for app and tray icons. Named icons are looked up in the icon
// theme and fall back to a generic app icon instead of Quickshell's missing
// icon checkerboard.

var fallbackIcon = "application-x-executable";

// An icon name, absolute path or URL, as found in desktop entries, window
// classes and notifications.
function forName(name) {
    if (!name)
        return "image://icon/" + fallbackIcon;
    if (name.startsWith("/"))
        return "file://" + name;
    if (name.indexOf("://") >= 0)
        return name;
    return "image://icon/" + name + "?fallback=" + fallbackIcon;
}

// A tray item's icon URL. Only plain named icons get the fallback: a `?path=`
// icon or a pixmap sent by the app is left as is.
function forTray(url) {
    if (!url)
        return forName("");
    if (url.startsWith("image://icon/") && url.indexOf("?") < 0)
        return forName(url.slice("image://icon/".length));
    return url;
}
