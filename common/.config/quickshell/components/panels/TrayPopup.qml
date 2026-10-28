import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../config" as Config
import "." as Panels
import "../IconSource.js" as IconSource

// The tray popup: the tray items, each opening its menu inline.
BarPopup {
    id: root

    property var selectedTrayItem: null
    property var menuStack: []

    function returnToParentMenu() {
        const parentStack = menuStack.slice(0, -1);

        menuStack = parentStack;
        trayMenu.menu = parentStack.length > 0
            ? parentStack[parentStack.length - 1] : selectedTrayItem.menu;
    }

    function triggerMenuEntry(entry) {
        entry.triggered();
        trayActionClose.restart();
    }

    onDismissed: {
        selectedTrayItem = null;
        menuStack = [];
    }
    popup: "tray"
    implicitWidth: 220

    Config.Theme {
        id: theme
    }

    QsMenuOpener {
        id: trayMenu
    }

    Timer {
        id: trayActionClose

        interval: 100
        onTriggered: root.popups.popupClosed("tray")
    }

    Column {
        id: trayList

        width: parent.width
        spacing: 2

        move: Transition {
            NumberAnimation {
                properties: "y"
                duration: 180
                easing.type: Easing.OutCubic
            }
        }

        PopupLabel {
            appearance: root.appearance
            visible: SystemTray.items.values.length === 0
            text: "No tray items"
            font.pixelSize: root.appearance.textSize - 1
        }

        Repeater {
            model: SystemTray.items

            delegate: Column {
                required property var modelData

                readonly property bool expanded: root.selectedTrayItem === modelData

                width: trayList.width
                height: trayItemRow.height + (expanded
                    ? inlineMenu.implicitHeight + spacing : 0)
                spacing: 0

                Behavior on height {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                PopupRow {
                    id: trayItemRow

                    appearance: root.appearance
                    width: parent.width
                    height: 34

                    Image {
                        id: trayIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        source: IconSource.forTray(modelData.icon)
                        fillMode: Image.PreserveAspectFit
                        visible: status === Image.Ready
                    }

                    Panels.Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !trayIcon.visible
                        text: "󰍜"
                        color: theme.textMuted
                        font.pixelSize: root.appearance.textSize
                    }

                    Panels.Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 36
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.tooltipTitle || modelData.title || modelData.id
                        color: trayItemRow.parent.expanded ? theme.accent : theme.text
                        elide: Text.ElideRight
                        font.pixelSize: root.appearance.textSize - 1
                    }

                    TapHandler {
                        onTapped: {
                            if (modelData.hasMenu) {
                                if (root.selectedTrayItem === modelData) {
                                    trayMenu.menu = null;
                                    root.selectedTrayItem = null;
                                    root.menuStack = [];
                                } else {
                                    root.selectedTrayItem = modelData;
                                    root.menuStack = [];
                                    trayMenu.menu = modelData.menu;
                                    modelData.opened();
                                }
                            } else {
                                modelData.activate();
                                root.popups.popupClosed("tray");
                            }
                        }
                    }
                }

                Column {
                    id: inlineMenu

                    width: parent.width
                    height: implicitHeight * (parent.expanded ? 1 : 0)
                    spacing: 0
                    opacity: parent.expanded ? 1 : 0
                    clip: true
                    visible: height > 0

                    Behavior on height {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 140
                            easing.type: Easing.OutCubic
                        }
                    }

                    PopupRow {
                        appearance: root.appearance
                        visible: root.menuStack.length > 0
                        width: parent.width
                        height: 30

                        Panels.Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 36
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰅁  Back"
                            color: theme.textMuted
                            font.pixelSize: root.appearance.textSize - 1
                        }

                        TapHandler {
                            onTapped: root.returnToParentMenu()
                        }
                    }

                    Repeater {
                        model: trayMenu.children

                        delegate: PopupRow {
                            required property var modelData

                            appearance: root.appearance
                            width: inlineMenu.width
                            height: modelData.isSeparator ? 9 : 30
                            interactive: !modelData.isSeparator && modelData.enabled

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 36
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                height: 1
                                visible: modelData.isSeparator
                                color: theme.border
                            }

                            Panels.Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 36
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                visible: !modelData.isSeparator
                                text: modelData.text + (modelData.hasChildren ? "  ›" : "")
                                color: modelData.enabled ? theme.text : theme.textDisabled
                                elide: Text.ElideRight
                                font.pixelSize: root.appearance.textSize - 1
                            }

                            TapHandler {
                                enabled: !modelData.isSeparator && modelData.enabled
                                onTapped: {
                                    if (modelData.hasChildren) {
                                        modelData.opened();
                                        root.menuStack = root.menuStack.concat([modelData]);
                                        trayMenu.menu = modelData;
                                    } else {
                                        root.triggerMenuEntry(modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
