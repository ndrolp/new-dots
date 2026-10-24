.pragma library

// Audio output naming, shared by every place that names one: pure logic, no
// Quickshell. Outputs are Quickshell PwNode objects, or anything with the same
// `nickname`, `description` and `name` fields.

// The name to show: the short nickname (PipeWire `node.nick`, e.g. the
// connected monitor or the headset model), else the long description, else
// the internal node name.
function label(output) {
    if (!output)
        return "";
    return String(output.nickname || output.description || output.name || "");
}
