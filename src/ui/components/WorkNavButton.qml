import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property string icon: "›"
    property bool enabled: true

    signal triggered()

    implicitWidth: 36
    implicitHeight: 36
    radius: 6
    color: enabled && navHover.containsMouse ? "#F3F4F6" : "white"
    border.color: enabled ? "#E5E7EB" : "#F3F4F6"
    border.width: 1
    opacity: enabled ? 1 : 0.4

    Label {
        anchors.centerIn: parent
        text: root.icon
        font.pixelSize: 18
        color: "#374151"
    }

    HoverHandler { id: navHover }
    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.triggered()
    }
}
