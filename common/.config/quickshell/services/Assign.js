.pragma library

// Sets `target[name]` to `value` only when it holds something else (compared
// as JSON), so the rows showing a list a service polls aren't rebuilt on
// every poll.
function ifChanged(target, name, value) {
    if (JSON.stringify(target[name]) !== JSON.stringify(value))
        target[name] = value;
}
