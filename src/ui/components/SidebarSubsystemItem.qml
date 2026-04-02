import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Sidebar item for a subsystem — shows icon, name, and delete on hover
Rectangle {
    id: root

    property string subsystemName: ""
    property string iconKey: "settings"
    property bool selected: false

    signal clicked()
    signal removeClicked()

    implicitHeight: 36
    color: selected ? "#EFF6FF" : (rowHover.containsMouse ? "#F1F5F9" : "transparent")
    radius: 6

    // Left selection indicator
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3; height: 20; radius: 2
        color: "#3B82F6"
        visible: root.selected
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 8
        spacing: 10

        Image {
            source: "qrc:/resources/icons/" + root.iconKey + ".svg"
            width: 16; height: 16
            opacity: root.selected ? 1.0 : 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        Label {
            text: root.subsystemName
            font.pixelSize: 13
            font.weight: root.selected ? Font.Medium : Font.Normal
            color: root.selected ? "#1D4ED8" : "#374151"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Delete button — visible on hover, handles its own click
        Rectangle {
            id: deleteBtn
            width: 20; height: 20; radius: 4
            visible: rowHover.containsMouse
            color: deleteArea.containsMouse ? "#FEE2E2" : "transparent"

            Label {
                anchors.centerIn: parent
                text: "×"; font.pixelSize: 14
                color: deleteArea.containsMouse ? "#DC2626" : "#9CA3AF"
            }

            HoverHandler { id: deleteArea }

            TapHandler {
                onTapped: root.removeClicked()
            }
        }
    }

    HoverHandler { id: rowHover }

    TapHandler {
        onTapped: {
            // Only fire if not tapping on the delete button
            if (!deleteBtn.visible || !deleteArea.containsMouse)
                root.clicked()
        }
    }
}
