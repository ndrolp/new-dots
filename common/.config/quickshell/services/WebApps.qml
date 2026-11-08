import Quickshell
import Quickshell.Io
import QtQuick
import "WebApps.js" as WebApps

// The web apps on this machine and what the web app maker does with them.
// The files are read and written by webapps.py; the rules (URLs, names,
// duplicates) are in WebApps.js. One of each command runs at a time, and a
// probe answer for a URL that is no longer wanted is dropped.
QtObject {
    id: root

    readonly property string script: Quickshell.shellDir + "/services/webapps.py"

    // Every web app: [{ id, name, url, icon }], sorted by name.
    property var apps: []
    // Whether the browser is installed; without it nothing can be created.
    property bool browserAvailable: true
    // The URL being probed, and what the probe found for `probedUrl`.
    property string probingUrl: ""
    property string probedUrl: ""
    property string probedName: ""
    property string probedIcon: ""
    readonly property bool probing: probeProcess.running
    // While the file chooser is open; the panel steps aside for it.
    readonly property bool pickingIcon: pickProcess.running
    readonly property bool creating: createProcess.running
    // Why the last create, delete or icon pick failed ("" otherwise).
    property string failure: ""

    // A local image was picked and converted: its PNG.
    signal iconPicked(string path)
    // A web app was created for `url`.
    signal created(string url)

    function refresh() {
        browserCheck.running = true;
        if (!listProcess.running)
            listProcess.running = true;
    }

    // Reads the name and icon of the page at `url` (a normalized URL).
    function probe(url) {
        probingUrl = url;
        if (url === "" || url === probedUrl)
            return;
        if (probeProcess.running) {
            probeProcess.pending = true;
            return;
        }
        startProbe();
    }

    function startProbe() {
        probeProcess.asked = probingUrl;
        probeProcess.command = ["python3", "-I", script, "probe", probingUrl];
        probeProcess.running = true;
    }

    function pickIcon() {
        if (pickProcess.running)
            return;
        failure = "";
        pickProcess.command = ["sh", "-c",
            "file=$(zenity --file-selection --title='Pick an icon' "
                + "--file-filter='Images | *.png *.jpg *.jpeg *.svg *.ico *.webp') || exit 0; "
                + "exec python3 -I \"$0\" icon \"$file\"",
            script];
        pickProcess.running = true;
    }

    function create(url, name, icon) {
        if (createProcess.running || !browserAvailable)
            return;
        failure = "";
        createProcess.url = url;
        createProcess.command = ["python3", "-I", script, "create", url, name].concat(icon ? [icon] : []);
        createProcess.running = true;
    }

    function remove(id) {
        failure = "";
        deleteProcess.command = ["python3", "-I", script, "delete", id];
        deleteProcess.running = true;
    }

    function launch(url) {
        Quickshell.execDetached(WebApps.launchCommand(url));
    }

    function parse(text, fallback) {
        try {
            return JSON.parse(text);
        } catch (error) {
            return fallback;
        }
    }

    property var browserCheck: Process {
        command: ["sh", "-c", "command -v \"$0\" >/dev/null", WebApps.browser]
        onExited: exitCode => root.browserAvailable = exitCode === 0
    }

    property var listProcess: Process {
        id: listProcess

        command: ["python3", "-I", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: root.apps = root.parse(text, root.apps)
        }
    }

    property var probeProcess: Process {
        id: probeProcess

        property string asked: ""
        property bool pending: false

        stdout: StdioCollector {
            onStreamFinished: {
                const found = root.parse(text, { title: "", icon: "" });
                if (probeProcess.asked !== root.probingUrl)
                    return;
                root.probedName = WebApps.nameFor(found.title, probeProcess.asked);
                root.probedIcon = found.icon || "";
                root.probedUrl = probeProcess.asked;
            }
        }
        onExited: {
            if (pending) {
                pending = false;
                if (root.probingUrl !== "" && root.probingUrl !== root.probedUrl)
                    root.startProbe();
            }
        }
    }

    property var pickProcess: Process {
        id: pickProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const picked = root.parse(text, null);
                if (picked && picked.icon)
                    root.iconPicked(picked.icon);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.failure = text.trim();
            }
        }
    }

    property var createProcess: Process {
        id: createProcess

        property string url: ""

        stderr: StdioCollector {
            id: createErrors
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                root.refresh();
                root.created(url);
            } else {
                root.failure = createErrors.text.trim() || "Couldn't create the web app";
            }
        }
    }

    property var deleteProcess: Process {
        id: deleteProcess

        stderr: StdioCollector {
            id: deleteErrors
        }
        onExited: exitCode => {
            if (exitCode !== 0)
                root.failure = deleteErrors.text.trim() || "Couldn't delete the web app";
            root.refresh();
        }
    }
}
