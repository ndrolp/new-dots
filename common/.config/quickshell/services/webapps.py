#!/usr/bin/env python3
"""Web apps on this machine: desktop entries that open a site in its own
Chrome window. WebApps.qml runs one command at a time and reads its JSON.

  webapps.py list                      every web app: [{id, name, url, icon}]
  webapps.py probe <url>               the page title and an icon: {title, icon}
  webapps.py icon <image>              a local image as a 256 px PNG: {icon}
  webapps.py create <url> <name> [png] writes the web app: {id}
  webapps.py delete <id>               removes it and its icon: {}

Web apps live in $XDG_DATA_HOME (~/.local/share): applications/<id>.desktop,
marked X-Webapp=true, and icons/hicolor/256x256/apps/<id>.png. Fetched and
converted icons wait in $XDG_CACHE_HOME/ndro-shell/webapps until created.
Errors go to stderr with exit status 1.
"""

import hashlib
import html.parser
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.parse

BROWSER = "google-chrome-stable"
FALLBACK_ICON = "applications-internet"
ICON_SIZE = 256
# Smaller icons only do when nothing better is found.
GOOD_SIZE = 64
TIMEOUT = 6
MAX_BYTES = 4 * 1024 * 1024
USER_AGENT = ("Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/130.0 Safari/537.36")

DATA = os.environ.get("XDG_DATA_HOME") or os.path.expanduser("~/.local/share")
CACHE = os.environ.get("XDG_CACHE_HOME") or os.path.expanduser("~/.cache")
APPS_DIR = os.path.join(DATA, "applications")
ICONS_DIR = os.path.join(DATA, "icons", "hicolor", f"{ICON_SIZE}x{ICON_SIZE}", "apps")
CACHE_DIR = os.path.join(CACHE, "ndro-shell", "webapps")
ID_PATTERN = re.compile(r"^webapp-[a-z0-9-]+$")


def fail(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def answer(value):
    print(json.dumps(value))


# --- Desktop entries ---------------------------------------------------------

def read_entry(path):
    """The [Desktop Entry] keys of a .desktop file."""
    keys = {}
    section = None
    with open(path, encoding="utf-8", errors="replace") as file:
        for line in file:
            line = line.strip()
            if line.startswith("["):
                section = line
            elif section == "[Desktop Entry]" and "=" in line and not line.startswith("#"):
                key, value = line.split("=", 1)
                keys.setdefault(key.strip(), value.strip())
    return keys


def unescape(value):
    return re.sub(r"\\(.)", lambda m: {"n": "\n", "t": "\t", "s": " "}.get(m.group(1), m.group(1)), value)


def escape(value):
    """A string value for a .desktop file."""
    return value.replace("\\", "\\\\").replace("\n", " ").replace("\t", " ")


def exec_argument(value):
    """One quoted argument of an Exec key: quoted for the spec, then escaped
    as a string, with % doubled so it isn't a field code."""
    quoted = '"' + re.sub(r'(["`$\\])', r"\\\1", value) + '"'
    return escape(quoted).replace("%", "%%")


def web_apps():
    apps = []
    if not os.path.isdir(APPS_DIR):
        return apps
    for name in sorted(os.listdir(APPS_DIR)):
        if not name.endswith(".desktop"):
            continue
        path = os.path.join(APPS_DIR, name)
        try:
            keys = read_entry(path)
        except OSError:
            continue
        if keys.get("X-Webapp") != "true":
            continue
        apps.append({
            "id": name[:-len(".desktop")],
            "name": unescape(keys.get("Name", "")),
            "url": unescape(keys.get("X-Webapp-Url", "")),
            "icon": keys.get("Icon", FALLBACK_ICON),
        })
    apps.sort(key=lambda app: app["name"].lower())
    return apps


def slug(name):
    text = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return text[:40].strip("-") or "app"


def window_class(url):
    """The class Chrome gives the window of --app=<url> (see WebApps.js)."""
    parts = urllib.parse.urlsplit(url)
    path = parts.path or "/"
    return "chrome-" + (parts.hostname or "") + "_" + path.replace("/", "_") + "-Default"


# --- Fetching ----------------------------------------------------------------

def fetch(url):
    """(bytes, final URL, content type) of `url`, following redirects. Uses
    curl: some sites reset urllib's connections. Raises on a failed fetch,
    an error status or a body over MAX_BYTES."""
    with tempfile.NamedTemporaryFile() as body:
        result = subprocess.run(
            ["curl", "--silent", "--fail", "--location", "--max-time", str(TIMEOUT),
             "--max-filesize", str(MAX_BYTES), "--user-agent", USER_AGENT,
             "--output", body.name, "--write-out", "%{url_effective}\n%{content_type}",
             "--", url],
            capture_output=True, text=True, timeout=TIMEOUT + 5)
        if result.returncode != 0:
            raise OSError("curl exited " + str(result.returncode) + " for " + url)
        final_url, _, content_type = result.stdout.partition("\n")
        return body.read(), final_url or url, content_type


class PageParser(html.parser.HTMLParser):
    """The title, icon links and manifest link of a page's <head>."""

    def __init__(self):
        super().__init__()
        self.title = ""
        self.in_title = False
        self.app_name = ""
        self.icons = []
        self.manifest = ""

    def handle_starttag(self, tag, attrs):
        attrs = {key: value or "" for key, value in attrs}
        if tag == "title" and not self.title:
            self.in_title = True
        elif tag == "meta" and not self.app_name:
            # The site's own short name beats a long marketing title.
            if (attrs.get("name", "").lower() in ("application-name", "apple-mobile-web-app-title")
                    or attrs.get("property", "").lower() == "og:site_name"):
                self.app_name = attrs.get("content", "").strip()
        elif tag == "link":
            rel = attrs.get("rel", "").lower().split()
            href = attrs.get("href", "")
            if not href:
                return
            if "manifest" in rel:
                self.manifest = href
            elif "icon" in rel or "apple-touch-icon" in rel or "apple-touch-icon-precomposed" in rel:
                size = 180 if any(r.startswith("apple-touch-icon") for r in rel) else 0
                self.icons.append((largest_size(attrs.get("sizes", ""), href) or size, href))

    def handle_endtag(self, tag):
        if tag == "title":
            self.in_title = False

    def handle_data(self, data):
        if self.in_title:
            self.title += data


def largest_size(sizes, href):
    """The largest side in a `sizes` attribute; an SVG scales to any."""
    if sizes.strip().lower() == "any" or href.lower().split("?")[0].endswith(".svg"):
        return 1024
    found = [int(side) for side in re.findall(r"(\d+)x\d+", sizes.lower())]
    return max(found) if found else 0


def read_page(page_url, body):
    """(name, [(size, url)…]) for a page. The name is the manifest's
    short_name or name, else the page's application-name or og:site_name,
    else its <title>. The icons are its manifest's and its link icons, the
    largest first, then /favicon.ico."""
    parser = PageParser()
    try:
        parser.feed(body.decode("utf-8", errors="replace"))
    except Exception:
        pass
    name = parser.app_name or parser.title
    candidates = [(size, urllib.parse.urljoin(page_url, href)) for size, href in parser.icons]
    if parser.manifest:
        manifest_url = urllib.parse.urljoin(page_url, parser.manifest)
        try:
            manifest = json.loads(fetch(manifest_url)[0].decode("utf-8", errors="replace"))
            name = str(manifest.get("short_name") or manifest.get("name") or "").strip() or name
            for icon in manifest.get("icons", []):
                if icon.get("src"):
                    candidates.append((largest_size(icon.get("sizes", ""), icon["src"]),
                                       urllib.parse.urljoin(manifest_url, icon["src"])))
        except Exception:
            pass
    candidates.sort(key=lambda candidate: -candidate[0])
    candidates.append((0, urllib.parse.urljoin(page_url, "/favicon.ico")))
    return name, candidates


# --- Icons -------------------------------------------------------------------

def frame_sizes(path):
    result = subprocess.run(["magick", "identify", "-format", "%w %h\n", path],
                            capture_output=True, text=True, timeout=20)
    if result.returncode != 0:
        return []
    sizes = []
    for line in result.stdout.splitlines():
        width, height = line.split()
        sizes.append(min(int(width), int(height)))
    return sizes


def to_png(source, target):
    """Converts an image (PNG, ICO, SVG, WebP…) to a square ICON_SIZE PNG,
    from its largest frame. Returns the size it had, or 0 when it isn't one."""
    sizes = frame_sizes(source)
    if not sizes:
        return 0
    frame = sizes.index(max(sizes))
    result = subprocess.run(
        ["magick", "-background", "none", "-density", "384", f"{source}[{frame}]",
         "-resize", f"{ICON_SIZE}x{ICON_SIZE}", "-gravity", "center",
         "-extent", f"{ICON_SIZE}x{ICON_SIZE}", f"PNG32:{target}"],
        capture_output=True, timeout=30)
    if result.returncode != 0 or not os.path.exists(target):
        return 0
    return max(sizes)


def cached_icon(key):
    os.makedirs(CACHE_DIR, exist_ok=True)
    return os.path.join(CACHE_DIR, hashlib.sha1(key.encode()).hexdigest()[:16] + ".png")


def fetch_icon(urls, target):
    """Fetches the first icon in `urls` at least GOOD_SIZE big into `target`,
    or failing that the biggest one found. Returns whether it got one."""
    best = 0
    with tempfile.TemporaryDirectory() as scratch:
        for index, url in enumerate(urls):
            try:
                data = fetch(url)[0]
            except Exception:
                continue
            raw = os.path.join(scratch, f"raw-{index}")
            png = os.path.join(scratch, f"icon-{index}.png")
            with open(raw, "wb") as file:
                file.write(data)
            size = to_png(raw, png)
            if size > best:
                best = size
                shutil.copyfile(png, target)
            if best >= GOOD_SIZE:
                break
    return best > 0


# --- Commands ----------------------------------------------------------------

def probe(url):
    title = ""
    urls = []
    try:
        body, final_url, content_type = fetch(url)
        if "html" in content_type or not content_type:
            title, candidates = read_page(final_url, body)
            urls = [candidate_url for _, candidate_url in candidates]
    except Exception:
        pass
    host = urllib.parse.urlsplit(url).hostname or ""
    urls.append("https://www.google.com/s2/favicons?domain=" + urllib.parse.quote(host)
                + f"&sz={ICON_SIZE}")
    target = cached_icon(url)
    icon = target if fetch_icon(urls, target) else ""
    answer({"title": re.sub(r"\s+", " ", title).strip(), "icon": icon})


def local_icon(path):
    target = cached_icon("file:" + os.path.abspath(path))
    if not os.path.isfile(path) or not to_png(path, target):
        fail("Couldn't read that image")
    answer({"icon": target})


def create(url, name, icon):
    if not name.strip():
        fail("A web app needs a name")
    for app in web_apps():
        if app["url"] == url:
            fail(app["name"] + " already opens this URL")
    os.makedirs(APPS_DIR, exist_ok=True)
    base = "webapp-" + slug(name)
    app_id = base
    number = 2
    while os.path.exists(os.path.join(APPS_DIR, app_id + ".desktop")):
        app_id = f"{base}-{number}"
        number += 1

    icon_value = FALLBACK_ICON
    if icon and os.path.isfile(icon):
        os.makedirs(ICONS_DIR, exist_ok=True)
        icon_value = os.path.join(ICONS_DIR, app_id + ".png")
        shutil.copyfile(icon, icon_value)

    entry = "\n".join([
        "[Desktop Entry]",
        "Type=Application",
        "Version=1.0",
        "Name=" + escape(name.strip()),
        "Comment=" + escape(url),
        "Exec=" + BROWSER + " " + exec_argument("--app=" + url),
        "Icon=" + icon_value,
        "Terminal=false",
        "Categories=Network;WebBrowser;",
        "StartupWMClass=" + window_class(url),
        "X-Webapp=true",
        "X-Webapp-Url=" + escape(url),
        "",
    ])
    path = os.path.join(APPS_DIR, app_id + ".desktop")
    with tempfile.NamedTemporaryFile("w", dir=APPS_DIR, delete=False, suffix=".tmp",
                                     encoding="utf-8") as file:
        file.write(entry)
    os.chmod(file.name, 0o644)
    os.replace(file.name, path)
    answer({"id": app_id})


def delete(app_id):
    if not ID_PATTERN.match(app_id):
        fail("Not a web app: " + app_id)
    path = os.path.join(APPS_DIR, app_id + ".desktop")
    if not os.path.isfile(path) or read_entry(path).get("X-Webapp") != "true":
        fail("Not a web app: " + app_id)
    icon = read_entry(path).get("Icon", "")
    os.remove(path)
    if os.path.dirname(icon) == ICONS_DIR and os.path.isfile(icon):
        os.remove(icon)
    answer({})


def main(argv):
    if len(argv) >= 1 and argv[0] == "list":
        answer(web_apps())
    elif len(argv) == 2 and argv[0] == "probe":
        probe(argv[1])
    elif len(argv) == 2 and argv[0] == "icon":
        local_icon(argv[1])
    elif len(argv) in (3, 4) and argv[0] == "create":
        create(argv[1], argv[2], argv[3] if len(argv) == 4 else "")
    elif len(argv) == 2 and argv[0] == "delete":
        delete(argv[1])
    else:
        fail(__doc__)


if __name__ == "__main__":
    main(sys.argv[1:])
