.pragma library

// Audio output naming, shared by every place that names one: pure logic, no
// Quickshell. Outputs are Quickshell PwNode objects, or anything with the same
// `nickname`, `description`, `name` and `properties` fields.

// The name to show: the short nickname (PipeWire `node.nick`, e.g. the
// connected monitor or the headset model), else the long description, else
// the internal node name.
function label(output) {
    if (!output)
        return "";
    return String(output.nickname || output.description || output.name || "");
}

// The port the output plays through (PipeWire `device.profile.description`,
// e.g. "HDMI / DisplayPort 1 Output", "Analog Stereo"): the secondary line
// under the label in output lists. Empty when the output has no port or the
// port only repeats the label (e.g. "Headphones" / "Headphones").
function port(output) {
    if (!output || !output.properties)
        return "";
    const value = String(output.properties["device.profile.description"] || "");
    return value === label(output) ? "" : value;
}
