import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Popup list for presets — replaces ComboBox with displayText "Пресеты"
// Usage:
//   PresetsPopup {
//       id: myPopup
//       presets: ["item1", "item2"]
//       onSelected: function(value) { ... }
//   }
//   ... button that calls myPopup.toggle(buttonItem)
Item {
    id: root

    property var presets: []
    property string buttonLabel: "Пресеты"

    signal selected(string value)

    // Call from outside to position and open/close
    function toggle(anchorItem) {
        if (popup.visible) {
            popup.close()
        } else {
            const pos = anchorItem.mapToItem(root.parent, 0, anchorItem.height + 4)
            popup.x = pos.x
            popup.y = pos.y
            popup.open()
        }
    }

    // The trigger button
    Rectangle {
        id: btn
        anchors.fill: parent
        radius: 6
        color: btnHover.containsMouse ? "#F3F4F6" : "white"
        border.color: "#E5E7EB"; border.width: 1

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
                text: "▾"; font.pixelSize: 10; color: "#9CA3AF"
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
        width: Math.max(200, root.width)
        padding: 0; modal: false; focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "white"; radius: 8
            border.color: "#E5E7EB"; border.width: 1
            layer.enabled: true
        }

        contentItem: Column {
            spacing: 0
            width: popup.width - 2

            Repeater {
                model: root.presets
                delegate: Rectangle {
                    width: parent.width; implicitHeight: 36
                    color: itemHover.containsMouse ? "#F3F4F6" : "white"
                    radius: index === 0 ? 8 : (index === root.presets.length - 1 ? 8 : 0)

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.right: parent.right; anchors.rightMargin: 12
                        text: modelData; font.pixelSize: 13; color: "#111827"
                        elide: Text.ElideRight
                    }

                    HoverHandler { id: itemHover }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
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
