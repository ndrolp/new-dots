import QtQuick
import QtTest
import "../services/Assign.js" as Assign

// A service's lists are only replaced when what they hold changes, so the
// rows showing them aren't rebuilt on every poll.
TestCase {
    name: "Assign"

    QtObject {
        id: target

        property var list: []
        property int changes: 0

        onListChanged: changes++
    }

    function test_aListIsOnlyReplacedWhenItChanges() {
        target.list = [{ name: "Office_Laser" }];
        target.changes = 0;
        const kept = target.list;
        Assign.ifChanged(target, "list", [{ name: "Office_Laser" }]);
        compare(target.changes, 0);
        verify(target.list === kept, "an equal list replaced the one there");
        Assign.ifChanged(target, "list", [{ name: "Office_Laser" }, { name: "Epson" }]);
        compare(target.changes, 1);
        compare(target.list.length, 2);
    }
}
