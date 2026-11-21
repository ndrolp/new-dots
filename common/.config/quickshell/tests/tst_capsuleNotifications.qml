import QtQuick
import QtTest
import "../config/BarProfileModel.js" as BarProfileModel
import "../config/SchemaMigrations.js" as SchemaMigrations
import "../components/bar/CapsuleNotificationQueue.js" as CapsuleNotificationQueue

// Notifications in the capsule: a capsule profile setting, off by default,
// that shows new notifications inside the focused monitor's capsule instead
// of as toasts.
TestCase {
    name: "CapsuleNotifications"

    // Every saved profile gets the setting, off, so nothing changes until it
    // is turned on.
    function test_migratedProfilesHaveNotificationsInTheCapsuleOff() {
        const profiles = SchemaMigrations.migrate({ schemaVersion: 19, barProfiles: {
            evening: { barStyle: "capsule" },
            work: { barStyle: "opaque" }
        } }, {}).appearance.barProfiles;

        compare(profiles.evening.capsuleNotifications, false);
        compare(profiles.work.capsuleNotifications, false);
    }

    // The queue after `notifications` arrive, oldest first.
    function arrivedAll(notifications) {
        return notifications.reduce((queue, notification) =>
            CapsuleNotificationQueue.arrived(queue, notification), CapsuleNotificationQueue.empty);
    }

    function test_nothingShowsAtFirst() {
        compare(CapsuleNotificationQueue.empty.shown, null);
        compare(CapsuleNotificationQueue.empty.waiting, []);
    }

    // The newest shows; the others wait, newest first, and count as "+N".
    function test_theNewestShowsAndTheOthersWait() {
        const queue = arrivedAll(["mail", "chat", "build"]);

        compare(queue.shown, "build");
        compare(queue.waiting, ["chat", "mail"]);
    }

    // When the shown one ends (its timeout, dismissed or acted on), the
    // newest waiting one shows next, until none is left.
    function test_whenTheShownOneEndsTheNextShows() {
        let queue = arrivedAll(["mail", "chat", "build"]);

        queue = CapsuleNotificationQueue.ended(queue, "build");
        compare(queue.shown, "chat");
        compare(queue.waiting, ["mail"]);

        queue = CapsuleNotificationQueue.ended(queue, "chat");
        queue = CapsuleNotificationQueue.ended(queue, "mail");
        compare(queue, CapsuleNotificationQueue.empty);
    }

    // One that ends while it waits (its app closed it, or its card left the
    // control center) leaves the queue without showing.
    function test_aWaitingOneThatEndsLeavesWithoutShowing() {
        const queue = CapsuleNotificationQueue.ended(arrivedAll(["mail", "chat", "build"]), "chat");

        compare(queue.shown, "build");
        compare(queue.waiting, ["mail"]);
    }

    function test_endingOneNotInTheQueueChangesNothing() {
        const queue = arrivedAll(["mail"]);

        compare(CapsuleNotificationQueue.ended(queue, "other"), queue);
    }

    // Leaving the capsule (a popup opening inside it, or it hiding for a
    // fullscreen window) hands every one still in it over, oldest first, to
    // show as toasts.
    function test_theQueueIsHandedOverOldestFirst() {
        compare(CapsuleNotificationQueue.all(arrivedAll(["mail", "chat", "build"])),
            ["mail", "chat", "build"]);
        compare(CapsuleNotificationQueue.all(CapsuleNotificationQueue.empty), []);
    }

    function test_newProfilesHaveNotificationsInTheCapsuleOff() {
        const profiles = BarProfileModel.defaultBarProfiles();

        for (const name in profiles)
            compare(BarProfileModel.completeProfile(profiles[name]).capsuleNotifications, false, name);
    }
}
