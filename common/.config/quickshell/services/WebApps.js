.pragma library

// The rules behind web apps: which text is a URL, the name a site gets when
// its title can't be read, which web app is a duplicate and the window class
// Chrome gives an `--app` window. Pure, no Quickshell; WebApps.qml carries
// them out with services/webapps.py.

// The browser every web app opens in.
var browser = "google-chrome-stable";

// The icon a web app gets when its site's can't be fetched.
var fallbackIcon = "applications-internet";

// The http(s) URL `text` means, or "" when it isn't one. A bare host
// (`youtube.com`) gets https; any other scheme is refused.
function normalize(text) {
    let url = String(text || "").trim();
    if (url === "" || /\s/.test(url))
        return "";

    if (!/^https?:\/\//i.test(url)) {
        // Any other scheme ("file:", "chrome:", "mailto:"…) is refused, but
        // "localhost:8080" is a host and a port.
        if (/^[a-z][a-z0-9+.-]*:/i.test(url) && !/^[^/:]+:\d+(\/|$)/.test(url))
            return "";
        url = "https://" + url;
    }

    const parts = split(url);
    if (!parts || !/^[a-z0-9.-]+(:\d+)?$/i.test(parts.authority)
            || parts.host.indexOf(".") < 0 && parts.host !== "localhost")
        return "";

    return parts.scheme + "://" + parts.authority.toLowerCase() + parts.rest;
}

// { scheme, authority, host, path, rest } of an http(s) URL; `rest` is
// everything after the authority ("/" when there is nothing), `path` the
// part of it before any query or fragment.
function split(url) {
    const match = /^(https?):\/\/([^/?#]*)(.*)$/i.exec(url);
    if (!match || match[2] === "")
        return null;

    const rest = match[3] === "" || match[3][0] !== "/" ? "/" + match[3] : match[3];
    return {
        scheme: match[1].toLowerCase(),
        authority: match[2],
        host: match[2].replace(/:\d+$/, "").toLowerCase(),
        path: rest.replace(/[?#].*$/, ""),
        rest: rest
    };
}

function host(url) {
    const parts = split(url);
    return parts ? parts.host : "";
}

// The name a web app gets when its page has no name: the label before the
// domain ending, capitalised ("web.whatsapp.com" → "Whatsapp").
function fallbackName(url) {
    const labels = host(url).split(".");
    const main = labels.length > 1 ? labels[labels.length - 2] : labels[0];
    return main === "" ? "" : main.charAt(0).toUpperCase() + main.slice(1);
}

// The name to offer for a page title: the title trimmed and collapsed, or
// the fallback name when it is empty.
function nameFor(title, url) {
    const name = String(title || "").replace(/\s+/g, " ").trim();
    return name !== "" ? name : fallbackName(url);
}

// The web app in `apps` that already opens exactly this URL, or null. Only
// the same URL counts: two web apps of one site are different web apps.
function duplicateOf(apps, url) {
    const wanted = normalize(url);
    for (let index = 0; index < apps.length; index++) {
        if (normalize(apps[index].url) === wanted)
            return apps[index];
    }
    return null;
}

// The class Chrome gives the window of `--app=<url>` on the default profile:
// "chrome-" + host + "_" + the path with each "/" as "_" + "-Default"
// (https://example.com/foo/bar → chrome-example.com__foo_bar-Default).
function windowClass(url) {
    const parts = split(url);
    return parts ? "chrome-" + parts.host + "_" + parts.path.replace(/\//g, "_") + "-Default" : "";
}

// The command that opens a web app.
function launchCommand(url) {
    return [browser, "--app=" + url];
}
