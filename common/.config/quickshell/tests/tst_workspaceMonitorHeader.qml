import QtQuick
import QtTest
import "../components/panels"

// The heading over a monitor's workspaces in the workspace overview.
Item {
    id: scene

    width: 300
    height: 60

    WorkspaceMonitorHeader {
        id: header

        width: 300
        appearance: ({ radius: 8, textSize: 14 })
        monitorName: "DP-1"
        canAddWorkspace: true
    }

    SignalSpy {
        id: added

        target: header
        signalName: "addWorkspaceRequested"
    }

    TestCase {
        name: "WorkspaceMonitorHeader"
        when: windowShown

        function init() {
            added.clear();
            header.canAddWorkspace = true;
        }

        function button() {
            return findChild(header, "addWorkspaceButton");
        }

        function test_thePlusAddsAWorkspace() {
            mouseClick(button());

            compare(added.count, 1);
        }

        function test_thePlusHidesWithNoNumberLeft() {
            header.canAddWorkspace = false;

            verify(!button().visible);
        }
    }
}
