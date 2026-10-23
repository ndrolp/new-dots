import QtQuick

// Reads the copies of the real config files in fixtures/ (see README.md).
QtObject {
    function read(fileName) {
        const request = new XMLHttpRequest();
        request.open("GET", Qt.resolvedUrl("fixtures/" + fileName), false);
        request.send(null);
        return JSON.parse(request.responseText);
    }
}
