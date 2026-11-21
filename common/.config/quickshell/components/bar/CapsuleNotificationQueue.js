.pragma library

// The notifications a capsule shows, with notifications in the capsule on:
// the one shown and those waiting, newest first, which the capsule counts as
// "+N". Pure functions over { shown, waiting }; they never mutate it. A
// notification is any value, compared with ===.

// Nothing shown and nothing waiting.
var empty = { shown: null, waiting: [] };

// A new notification shows at once; the one it replaces waits, newest first.
function arrived(queue, notification) {
    return {
        shown: notification,
        waiting: (queue.shown === null ? [] : [queue.shown]).concat(queue.waiting)
    };
}

// `notification` is done (its timeout ran out, it was dismissed or acted on,
// or its app closed it): when it was the one shown, the newest waiting one
// shows next; when it was waiting, it leaves without showing.
function ended(queue, notification) {
    if (queue.shown === notification) {
        return queue.waiting.length === 0 ? empty
            : { shown: queue.waiting[0], waiting: queue.waiting.slice(1) };
    }
    if (queue.waiting.indexOf(notification) === -1)
        return queue;
    return { shown: queue.shown, waiting: queue.waiting.filter(waiting => waiting !== notification) };
}

// Every notification in the queue, oldest first: what a capsule hands over to
// show as toasts when it can't show them any more.
function all(queue) {
    return (queue.shown === null ? [] : [queue.shown]).concat(queue.waiting).reverse();
}
