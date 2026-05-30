import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Popup list for presets — dark style matching the add-subsystem dialog
// Usage:
//   PresetsPopup {
//       id: myPopup
//       presets: ["item1", "item2"]
//       onSelected: function(value) { ... }
//   }
//   ... trigger button calls myPopup.toggle(buttonItem)
Item {
    id: root

    property var presets: []
    property string buttonLabel: "Пресеты"

    signal selected(string value)

    function toggle(anchorItem) {
        if (popup.visible) {
            popup.close()
        } else {
            const globalPos = anchorItem.mapToItem(root.parent, 0, anchorItem.height + 6)
            popup.x = globalPos.x
            popup.y = globalPos.y
            popup.open()
        }
    }

    // Trigger button
    Rectangle {
        id: btn
        anchors.fill: parent
        radius: 6
        color: btnHover.containsMouse || popup.visible ? "#F3F4F6" : "white"
        border.color: popup.visible ? "#0EA5E9" : "#E5E7EB"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 8
            spacing: 4

            Label {
                text: root.buttonLabel
                font.pixelSize: 13; color: "#374151"
                Layout.fillWidth: true
            }

            Label {
                text: popup.visible ? "▴" : "▾"
                font.pixelSize: 9; color: "#9CA3AF"
            }
        }

        HoverHandler { id: btnHover }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: root.toggle(btn)
        }
    }

    Popup {
        id: popup
        width: Math.max(220, root.width)
        padding: 6
        modal: false; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "#0369A1"
            radius: 8
            border.color: "#075985"; border.width: 1
        }

        contentItem: Column {
            spacing: 2
            width: popup.width - 12

            Repeater {
                model: root.presets
                delegate: Rectangle {
                    width: parent.width; implicitHeight: 36
                    radius: 6
                    color: itemMouse.containsMouse ? "#075985" : "transparent"

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.right: parent.right; anchors.rightMargin: 12
                        text: modelData
                        font.pixelSize: 13; color: "#E2E8F0"
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selected(modelData)
                            popup.close()
                        }
                    }
                }
            }
        }
    }
}
