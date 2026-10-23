import QtQuick

// The Bar section: one bar profile selector, then every setting the edited
// profile stores (Size & spacing, Style, Elements).
Column {
    id: root

    property var appearance

    width: parent ? parent.width : 0
    spacing: 12

    BarProfileSelector {
        appearance: root.appearance
    }

    BarSizeStyleSettings {
        appearance: root.appearance
    }

    BarElementsSettings {
        appearance: root.appearance
    }
}
