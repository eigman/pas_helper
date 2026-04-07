import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var presets: []
    property string buttonLabel: "Пресеты"

    signal apply(string text)

    property var counts: []

    // Strip leading "Nx " prefix — display name is always the base name
    function baseName(s) {
        return s.replace(/^\d+x\s+/i, "")
    }

    function resetCounts() {
        var c = []
        for (var i = 0; i < presets.length; i++) c.push(0)
        counts = c
    }

    function buildResult() {
        var parts = []
        for (var i = 0; i < presets.length; i++) {
            var n = counts[i] || 0
            if (n > 0)
                parts.push(n + "x " + baseName(presets[i]))
        }
        return parts.join(" \\n ")
    }

    // Trigger button
    Rectangle {
        id: btn
        anchors.fill: parent
        radius: 6
        color: btnHover.containsMouse ? "#EFF6FF" : "transparent"

        Row {
            anchors.centerIn: parent; spacing: 4
            Text { text: root.buttonLabel; font.pixelSize: 12; color: "#3B82F6"; anchors.verticalCenter: parent.verticalCenter }
            Text { text: "＋"; font.pixelSize: 11; color: "#3B82F6"; anchors.verticalCenter: parent.verticalCenter }
        }

        HoverHandler { id: btnHover }
        MouseArea {
            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
            onClicked: { root.resetCounts(); dialog.open() }
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
                    text: "Выбрать интерфейсы"
                    font.pixelSize: 15; font.weight: Font.Medium; color: "#111827"
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: "#E5E7EB" }
            }

            // Scrollable list
            ScrollView {
                width: parent.width
                height: Math.min(root.presets.length * 52, 364)
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                Column {
                    width: dialog.width
                    spacing: 0

                    Repeater {
                        model: root.presets
                        delegate: Rectangle {
                            width: parent.width; height: 52
                            color: "white"

                            property int qty: root.counts[index] || 0

                            Rectangle {
                                visible: index > 0
                                anchors.top: parent.top
                                anchors.left: parent.left; anchors.right: parent.right
                                anchors.leftMargin: 20; anchors.rightMargin: 20
                                height: 1; color: "#F3F4F6"
                            }

                            // Base name (no Nx prefix)
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left; anchors.leftMargin: 20
                                anchors.right: controls.left; anchors.rightMargin: 16
                                text: root.baseName(modelData)
                                font.pixelSize: 14
                                color: qty > 0 ? "#1D4ED8" : "#111827"
                                elide: Text.ElideRight
                            }

                            // +/- controls — spaced from scroll bar
                            Row {
                                id: controls
                                anchors.right: parent.right
                                anchors.rightMargin: 28   // extra margin from scroll bar
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                // Minus
                                Rectangle {
                                    width: 28; height: 28; radius: 6
                                    visible: qty > 0
                                    color: minusHover.containsMouse ? "#FEE2E2" : "#F3F4F6"
                                    Text {
                                        anchors.centerIn: parent; text: "−"
                                        font.pixelSize: 16
                                        color: minusHover.containsMouse ? "#DC2626" : "#6B7280"
                                    }
                                    HoverHandler { id: minusHover }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var c = root.counts.slice()
                                            c[index] = Math.max(0, c[index] - 1)
                                            root.counts = c
                                        }
                                    }
                                }

                                // Count badge
                                Rectangle {
                                    width: 28; height: 28; radius: 6
                                    visible: qty > 0
                                    color: "#EFF6FF"
                                    Text {
                                        anchors.centerIn: parent; text: qty
                                        font.pixelSize: 14; font.weight: Font.Medium; color: "#1D4ED8"
                                    }
                                }

                                // Plus
                                Rectangle {
                                    width: 28; height: 28; radius: 6
                                    color: plusHover.containsMouse ? "#DBEAFE" : "#EFF6FF"
                                    Text {
                                        anchors.centerIn: parent; text: "+"
                                        font.pixelSize: 16; color: "#3B82F6"
                                    }
                                    HoverHandler { id: plusHover }
                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var c = root.counts.slice()
                                            c[index] = (c[index] || 0) + 1
                                            root.counts = c
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Footer
            Item {
                width: parent.width; height: 60
                Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: "#E5E7EB" }

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: insertLbl.implicitWidth + 36; height: 38; radius: 8
                        color: insertHover.containsMouse ? "#1D4ED8" : "#3B82F6"
                        Text { id: insertLbl; anchors.centerIn: parent; text: "Вставить"; font.pixelSize: 14; color: "white" }
                        HoverHandler { id: insertHover }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var result = root.buildResult()
                                if (result !== "") root.apply(result)
                                dialog.close()
                            }
                        }
                    }

                    Rectangle {
                        width: closeLbl.implicitWidth + 36; height: 38; radius: 8
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
}
