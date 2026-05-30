import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// RAM picker that pops up above the trigger button.
// Left column: DDR generation chips. Right column: capacity chips.
// Emits selected(string) when user picks both, e.g. "DDR4 16384 MB"
Item {
    id: root

    property string buttonLabel: "ОЗУ +"

    signal selected(string value)

    property string _gen: ""
    property string _cap: ""

    function _tryEmit() {
        if (_gen !== "" && _cap !== "") {
            root.selected(_gen + " " + _cap + " MB")
            _gen = ""
            _cap = ""
            popup.close()
        }
    }

    // Trigger button
    Rectangle {
        id: btn
        anchors.fill: parent
        radius: 6
        color: btnHover.containsMouse ? "#E0F2FE" : "transparent"

        Text {
            anchors.centerIn: parent
            text: root.buttonLabel; font.pixelSize: 12; color: "#0EA5E9"
        }

        HoverHandler { id: btnHover }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: {
                root._gen = ""
                root._cap = ""
                var p = btn.mapToItem(Overlay.overlay, 0, 0)
                popup.x = p.x + btn.width - popup.width
                popup.y = p.y - popup.height - 4
                popup.open()
            }
        }
    }

    Popup {
        id: popup
        parent: Overlay.overlay
        width: 300
        padding: 12
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: "white"; radius: 10
            border.color: "#E5E7EB"; border.width: 1
        }

        contentItem: Column {
            spacing: 10
            width: popup.width - 24  // popup.padding * 2

            // Header
            Text {
                text: "Выберите поколение и объём"
                font.pixelSize: 12; color: "#6B7280"
            }

            // Body row
            Row {
                width: parent.width
                spacing: 0

                // Left — DDR generation
                Column {
                    spacing: 6
                    width: 116

                    Text {
                        text: "Поколение"
                        font.pixelSize: 11; color: "#9CA3AF"
                        height: 18; verticalAlignment: Text.AlignVCenter
                    }

                    Repeater {
                        model: ["DDR2", "DDR3", "DDR4", "DDR5"]
                        delegate: Rectangle {
                            width: 100; height: 32; radius: 16
                            color: root._gen === modelData ? "#0EA5E9" : (chipHoverG.containsMouse ? "#E0F2FE" : "#F3F4F6")
                            border.color: root._gen === modelData ? "#0EA5E9" : "#E5E7EB"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData; font.pixelSize: 13
                                font.weight: root._gen === modelData ? Font.Medium : Font.Normal
                                color: root._gen === modelData ? "white" : "#374151"
                            }

                            HoverHandler { id: chipHoverG }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { root._gen = modelData; root._tryEmit() }
                            }
                        }
                    }
                }

                // Divider — height matches the shorter (right) column: label(18) + 3*chip(32) + 2*spacing(6) = 126
                Rectangle {
                    width: 1
                    height: 18 + 3 * 32 + 2 * 6
                    color: "#E5E7EB"
                    anchors.top: parent.top
                }

                // Right — capacity
                Column {
                    spacing: 6
                    width: parent.width - 116 - 1
                    leftPadding: 12

                    Text {
                        text: "Объём"
                        font.pixelSize: 11; color: "#9CA3AF"
                        height: 18; verticalAlignment: Text.AlignVCenter
                    }

                    Grid {
                        columns: 2
                        spacing: 6
                        width: parent.width - parent.leftPadding

                        Repeater {
                            model: ["2048", "4096", "8192", "16384", "32768", "65536"]
                            delegate: Rectangle {
                                width: (parent.width - 6) / 2
                                height: 32; radius: 16
                                color: root._cap === modelData ? "#0EA5E9" : (chipHoverC.containsMouse ? "#E0F2FE" : "#F3F4F6")
                                border.color: root._cap === modelData ? "#0EA5E9" : "#E5E7EB"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: {
                                        const mb = parseInt(modelData)
                                        return mb >= 1024 ? (mb / 1024) + " GB" : mb + " MB"
                                    }
                                    font.pixelSize: 13
                                    font.weight: root._cap === modelData ? Font.Medium : Font.Normal
                                    color: root._cap === modelData ? "white" : "#374151"
                                }

                                HoverHandler { id: chipHoverC }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: { root._cap = modelData; root._tryEmit() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
