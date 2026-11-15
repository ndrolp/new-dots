.pragma library

// The discovered printers: IPP printers avahi sees on the network, and USB
// ones ipp-usb serves as IPP on localhost, read from what `avahi-browse -rpk`
// streams, without the ones already added. Pure, no Quickshell;
// DiscoveredPrinters.qml runs the commands.

// avahi-browse escapes a service name byte by byte: "\032" is a space
// (decimal), "\." a dot and "\\" a backslash.
function unescapeName(text) {
    const bytes = [];
    for (let i = 0; i < text.length; i++) {
        const digits = /^\\(\d{3})/.exec(text.slice(i, i + 4));
        if (digits) {
            bytes.push(parseInt(digits[1], 10));
            i += 3;
        } else if (text[i] === "\\" && i + 1 < text.length) {
            bytes.push(text.charCodeAt(++i));
        } else {
            const code = text.charCodeAt(i);
            if (code < 0x80)
                bytes.push(code);
            else
                for (const byte of unescape(encodeURIComponent(text[i])).split(""))
                    bytes.push(byte.charCodeAt(0));
        }
    }
    const latin = bytes.map(byte => String.fromCharCode(byte)).join("");
    try {
        return decodeURIComponent(escape(latin));
    } catch (error) {
        return latin;
    }
}

// The TXT record avahi-browse prints: "key=value" strings in double quotes,
// with \" and \\ escaped. Keys are case-insensitive, so they're lowercased.
function parseTxt(text) {
    const txt = {};
    const pattern = /"((?:[^"\\]|\\.)*)"/g;
    let match;
    while ((match = pattern.exec(text)) !== null) {
        const entry = unescapeName(match[1]);
        const equals = entry.indexOf("=");
        if (equals > 0)
            txt[entry.slice(0, equals).toLowerCase()] = entry.slice(equals + 1);
    }
    return txt;
}

// `services` with one line of `avahi-browse -rpk` taken in: a resolved
// service ("=") is kept by interface, protocol, name and type, and one that
// went away ("-") is dropped. Returns a new object; `services` stays as is.
function takeLine(services, line) {
    const fields = String(line).split(";");
    if (fields.length < 6 || (fields[0] !== "=" && fields[0] !== "-"))
        return services;
    const key = fields.slice(1, 6).join(";");
    const next = Object.assign({}, services);
    if (fields[0] === "-") {
        if (!(key in next))
            return services;
        delete next[key];
        return next;
    }
    if (fields.length < 10)
        return services;
    next[key] = {
        iface: fields[1],
        protocol: fields[2],
        name: unescapeName(fields[3]),
        type: fields[4],
        domain: fields[5],
        hostname: fields[6].toLowerCase().replace(/\.$/, ""),
        address: fields[7].toLowerCase(),
        port: parseInt(fields[8], 10) || 631,
        txt: parseTxt(fields.slice(9).join(";"))
    };
    return next;
}

// ipp-usb advertises USB printers on the loopback interface.
function isUsb(service) {
    return service.iface === "lo";
}

// This computer's CUPS advertises the printers it shares on lo too, as
// printers/<name> or classes/<name>; those are already added.
function isOwnPrinter(service) {
    return isUsb(service) && /^(printers|classes)\//.test(service.txt.rp || "");
}

function uriOf(service) {
    const query = service.txt.uuid ? "?uuid=" + service.txt.uuid : "";
    if (isUsb(service))
        return "ipp://localhost:" + service.port + "/" + (service.txt.rp || "ipp/print");
    return "dnssd://" + encodeURIComponent(service.name) + "." + service.type + "."
        + service.domain + "/" + query;
}

// Can the printer print without a driver (IPP Everywhere, AirPrint or
// PDF)? A printer that doesn't say what it takes gets the benefit of the doubt.
function isDriverless(service) {
    const pdl = service.txt.pdl;
    if (pdl === undefined)
        return true;
    return /image\/pwg-raster|image\/urf|application\/pdf/i.test(pdl) || service.txt.urf !== undefined;
}

// The record that stands for a printer seen several times: over IPP rather
// than IPPS, IPv4 rather than IPv6.
function rank(service) {
    return (service.type === "_ipp._tcp" ? 0 : 2) + (service.protocol === "IPv4" ? 0 : 1);
}

// Streams every IPP (or IPPS) printer as it appears ("="), resolved, and
// disappears ("-"), without looking service types up (-k), until killed.
function browseCommand(type) {
    return ["avahi-browse", "-rpk", type];
}

// The device URIs of the printers added, for addedUris().
var addedCommand = ["env", "LC_ALL=C", "lpstat", "-v"];

// Why printers can't be found, from what avahi-browse printed on stderr
// ("" when nothing stops it: a printer that doesn't resolve isn't a problem).
function browseProblem(stderr) {
    const lines = String(stderr || "").split("\n").map(line => line.trim())
        .filter(line => line !== "" && !line.startsWith("Failed to resolve service"));
    if (lines.length === 0)
        return "";
    if (lines.some(line => /Daemon not running|Daemon connection failed/i.test(line)))
        return "avahi-daemon isn't running, so printers on the network and USB can't be found. "
            + "Start it with: systemctl enable --now avahi-daemon";
    return "Can't look for printers: " + lines[0];
}

// A CUPS printer name for `model`: letters, digits, - and _ only (CUPS
// refuses spaces, / and #, and other apps choke on the rest), with a
// number when `takenNames` already has it (CUPS ignores case).
function printerName(model, takenNames) {
    const base = String(model || "").replace(/[^A-Za-z0-9_-]+/g, "_").replace(/^_+|_+$/g, "").slice(0, 120)
        || "Printer";
    const taken = (takenNames || []).map(name => String(name).toLowerCase());
    let name = base;
    for (let number = 2; taken.indexOf(name.toLowerCase()) >= 0; number++)
        name = base + "_" + number;
    return name;
}

// Adds `printer`, a discovered one, driverless (IPP Everywhere), named after
// its model and enabled. The user is in wheel, which CUPS on Arch takes as
// an admin group, so it needs no password.
function addCommand(printer, takenNames) {
    return ["lpadmin", "-p", printerName(printer.model, takenNames), "-E", "-v", printer.uri, "-m", "everywhere"];
}

// What the Printers panel says when adding `model` failed, from lpadmin's stderr.
function addProblem(stderr, model) {
    const line = String(stderr || "").split("\n").map(text => text.replace(/^lpadmin:\s*/, "").trim())
        .find(text => text !== "");
    return "Couldn't add " + model + " driverless" + (line ? ": " + line : "");
}

// The parts of a device URI that tell which printer it is: its host (no
// brackets, lowercase, no trailing dot), port, the service name of a
// dnssd:// one and the uuid in its query.
function partsOf(uri) {
    const match = /^([a-z0-9+.-]+):\/\/(\[[^\]]*\]|[^/:?]*)(?::(\d+))?([^?]*)(?:\?(.*))?$/i.exec(String(uri).trim());
    if (!match)
        return null;
    const host = decodeURIComponent(match[2]).replace(/^\[|\]$/g, "").toLowerCase().replace(/\.$/, "");
    const uuid = /(?:^|&)uuid=([^&]*)/i.exec(match[5] || "");
    const service = /^(.*)\._ipps?\._tcp\.[^.]+$/.exec(host);
    return {
        scheme: match[1].toLowerCase(),
        host: host,
        port: match[3] ? parseInt(match[3], 10) : 0,
        service: match[1].toLowerCase() === "dnssd" && service ? service[1] : "",
        uuid: uuid ? uuid[1].toLowerCase() : ""
    };
}

function isLoopback(host) {
    return host === "localhost" || host === "::1" || host.startsWith("127.");
}

// Is the added printer with device URI `uri` one of the records in `group`
// (the same printer, seen several ways)? By its uuid, its dnssd name, or
// the host it's at; ipp-usb serves each USB printer on its own localhost
// port, so for those the port tells.
function isAddedAs(group, uri) {
    const parts = partsOf(uri);
    if (!parts)
        return false;
    return group.some(service => {
        if (parts.uuid !== "" && parts.uuid === String(service.txt.uuid || "").toLowerCase())
            return true;
        if (parts.service !== "")
            return parts.service === service.name.toLowerCase();
        if (isLoopback(parts.host))
            return isUsb(service) && (parts.port || 631) === service.port;
        return !isUsb(service) && parts.host !== ""
            && (parts.host === service.hostname || parts.host === service.address);
    });
}

// The device URIs in what `lpstat -v` prints under LC_ALL=C.
function addedUris(text) {
    const uris = [];
    for (const line of String(text || "").split("\n")) {
        const device = /^device for \S+: (.*)$/.exec(line);
        if (device)
            uris.push(device[1].trim());
    }
    return uris;
}

// Every printer in `services` that isn't added yet: [{ key, model, service,
// connection, uri, driverless }], by model. A printer seen on several
// interfaces, protocols or types is one, told apart by its UUID or name.
// `addedUris` are the device URIs of the printers added.
function discovered(services, addedUris) {
    const groups = {};
    for (const id of Object.keys(services)) {
        const service = services[id];
        if (isOwnPrinter(service))
            continue;
        const key = (service.txt.uuid || service.name).toLowerCase();
        (groups[key] = groups[key] || []).push(service);
    }
    const printers = [];
    for (const key of Object.keys(groups)) {
        const group = groups[key].sort((first, second) => rank(first) - rank(second));
        if ((addedUris || []).some(uri => isAddedAs(group, uri)))
            continue;
        const best = group[0];
        printers.push({
            key: key,
            model: best.txt.ty || best.name,
            service: best.name,
            connection: isUsb(best) ? "usb" : "network",
            uri: uriOf(best),
            driverless: isDriverless(best)
        });
    }
    return printers.sort((first, second) => first.model.localeCompare(second.model)
        || first.key.localeCompare(second.key));
}
