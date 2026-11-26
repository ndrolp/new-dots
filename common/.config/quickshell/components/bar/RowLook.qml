import QtQuick

// Gives `target`, a bar element's item, how it looks in the capsule's row:
// `look`'s opacity and scale, and its slide along the row as a Translate
// (CapsuleMotion.rowLook, cardLook). Put it inside the item it gives the look
// to, as one line instead of three bindings; the item sets none of the three
// itself.
QtObject {
    id: root

    // The item that takes the look.
    required property Item target
    // How it looks, { opacity, scale, slide }.
    required property var look

    readonly property Translate slide: Translate {
        x: root.look.slide
    }

    readonly property list<QtObject> bindings: [
        Binding {
            target: root.target
            property: "opacity"
            value: root.look.opacity
        },
        Binding {
            target: root.target
            property: "scale"
            value: root.look.scale
        }
    ]

    Component.onCompleted: target.transform = [slide]
}
