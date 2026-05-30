import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Generic sidebar navigation item with icon + label
Rectangle {
    id: root

    property string iconSource: ""
    property string label: ""
    property bool selected: false

    signal clicked()

    implicitHeight: 36
    color: selected ? "#E0F2FE" : (hoverHandler.containsMouse ? "#F1F5F9" : "transparent")
    radius: 6

    // Left selection indicator
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 20
        radius: 2
        color: "#0EA5E9"
        visible: root.selected
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 10

        Image {
            source: root.iconSource
            width: 16
            height: 16
            opacity: root.selected ? 1.0 : 0.5
            Layout.alignment: Qt.AlignVCenter
        }

        Label {
            text: root.label
            font.pixelSize: 13
            font.weight: root.selected ? Font.Medium : Font.Normal
            color: root.selected ? "#0284C7" : "#374151"
            Layout.fillWidth: true
            elide: Text.ElideRight
        }
    }

    HoverHandler { id: hoverHandler }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
