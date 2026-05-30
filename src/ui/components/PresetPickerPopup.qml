import QtQuick
import QtQuick.Controls

// Modal picker dialog — same style as "Add subsystem" dialog
// Clicking an item immediately emits selected() and closes
Item {
    id: root

    property var presets: []
    property string buttonLabel: "Пресеты"
    property string dialogTitle: "Выбрать пресет"

    signal selected(string value)

    // Small blue trigger button
    Rectangle {
        id: btn
        anchors.fill: parent
        radius: 6
        color: btnHover.containsMouse ? "#E0F2FE" : "transparent"

        Row {
            anchors.centerIn: parent; spacing: 4
            Text { text: root.buttonLabel; font.pixelSize: 12; color: "#0EA5E9"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "＋"; font.pixelSize: 11; color: "#0EA5E9"; anchors.verticalCenter: parent.verticalCenter }
        }

        HoverHandler { id: btnHover }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: dialog.open()
        }
    }

    Popup {
        id: dialog
        parent: Overlay.overlay
        anchors.centerIn: parent
        width: 420
        padding: 0
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            color: "white"; radius: 10
            border.color: "#E5E7EB"; border.width: 1
        }

        contentItem: Column {
            spacing: 0
            width: dialog.width

            // Header
            Item {
                width: parent.width; height: 56
                Text {
                    anchors.left: parent.left; anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dialogTitle
                    font.pixelSize: 15; font.weight: Font.Medium; color: "#111827"
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#E5E7EB" }
            }

            // Items — scrollable, fixed height
            ScrollView {
                width: parent.width
                height: Math.min(root.presets.length * 48, 360)
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: dialog.width
                    spacing: 0

                    Repeater {
                        model: root.presets
                        delegate: Rectangle {
                            width: parent.width; height: 48
                            color: itemMouse.containsMouse ? "#F3F4F6" : "white"

                            Rectangle { visible: index > 0; anchors.top: parent.top; width: parent.width; height: 1; color: "#F3F4F6" }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 20
                                anchors.right: parent.right; anchors.rightMargin: 20
                                text: modelData; font.pixelSize: 14; color: "#111827"
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: itemMouse; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { root.selected(modelData); dialog.close() }
                            }
                        }
                    }
                }
            }

            // Footer
            Item {
                width: parent.width; height: 52
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#E5E7EB" }
                Rectangle {
                    anchors.centerIn: parent
                    width: closeLbl.implicitWidth + 32; height: 36; radius: 6
                    color: closeHover.containsMouse ? "#F3F4F6" : "white"
                    border.color: "#E5E7EB"; border.width: 1
                    Text { id: closeLbl; anchors.centerIn: parent; text: "Закрыть"; font.pixelSize: 14; color: "#374151" }
                    HoverHandler { id: closeHover }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: dialog.close() }
                }
            }
        }
    }
}
