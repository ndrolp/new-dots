import QtQuick

// A wallpaper's thumbnail in the picker and the selector: the file of its
// row (WallpaperFiles' filePath), decoded at the height it is shown.
Image {
    required property string filePath
    // The height to decode it at, in device pixels.
    property int decodeHeight: 0

    anchors.fill: parent
    source: filePath === "" ? "" : "file://" + filePath
    sourceSize.height: decodeHeight
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
}
