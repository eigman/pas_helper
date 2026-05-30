import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string subsystemName: ""
    property string iconKey: "settings"
    property bool selected: false

    signal clicked()
    signal removeClicked()

    implicitHeight: 36
    color: selected ? "#E0F2FE" : (rowHover.hovered ? "#F1F5F9" : "transparent")
    radius: 6

    // Left selection indicator
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3; height: 20; radius: 2
        color: "#0EA5E9"
        visible: root.selected
    }

    // Icon
    Image {
        id: icon
        x: 16; anchors.verticalCenter: parent.verticalCenter
        source: "qrc:/resources/icons/" + root.iconKey + ".svg"
        width: 16; height: 16
        opacity: root.selected ? 1.0 : 0.5
    }

    // Label
    Text {
        anchors.left: icon.right; anchors.leftMargin: 10
        anchors.right: deleteArea.visible ? deleteArea.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.subsystemName
        font.pixelSize: 13
        font.weight: root.selected ? Font.Medium : Font.Normal
        color: root.selected ? "#0284C7" : "#374151"
        elide: Text.ElideRight
    }

    // Delete button — always present, only visible on hover
    Rectangle {
        id: deleteArea
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 20; height: 20; radius: 4
        visible: rowHover.hovered
        color: deleteHover.hovered ? "#FEE2E2" : "transparent"
        z: 2

        Text {
            anchors.centerIn: parent
            text: "×"; font.pixelSize: 15
            color: deleteHover.hovered ? "#DC2626" : "#9CA3AF"
        }

        HoverHandler { id: deleteHover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            z: 2
            onClicked: function(mouse) {
                mouse.accepted = true
                root.removeClicked()
            }
        }
    }

    // Row hover tracker
    HoverHandler { id: rowHover }

    // Row click — fires only when not over delete button
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        z: 1
        onClicked: function(mouse) {
            if (!deleteHover.hovered) {
                root.clicked()
            }
        }
    }
}
