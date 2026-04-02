import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Recommendations editor — free text with @ul / @ol helper buttons
Item {
    id: root

    signal saveAsRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Page header ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 60
            color: "white"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width; height: 1; color: "#E5E7EB"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 32; anchors.rightMargin: 32; spacing: 12

                Label {
                    text: "Рекомендации"
                    font.pixelSize: 20; font.weight: Font.Medium
                    color: "#111827"; Layout.fillWidth: true
                }

                // Insert helpers
                Label {
                    text: "Вставить:"
                    font.pixelSize: 12; color: "#9CA3AF"
                }

                Repeater {
                    model: [
                        { label: "@ul список",       block: "@ul\n@item \n@endul\n" },
                        { label: "@ol нумер.",        block: "@ol\n@item \n@endol\n" },
                        { label: "@hint",             block: "@hint\n\n@endhint\n"  },
                        { label: "@caution",          block: "@caution\n\n@endcaution\n" }
                    ]
                    delegate: Rectangle {
                        implicitWidth: insertBtnLabel.implicitWidth + 16
                        implicitHeight: 28; radius: 6
                        color: insertBtnHover.containsMouse ? "#F3F4F6" : "transparent"
                        border.color: "#E5E7EB"; border.width: 1

                        Label {
                            id: insertBtnLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            font.pixelSize: 11; font.family: "monospace"
                            color: "#374151"
                        }

                        HoverHandler { id: insertBtnHover }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertBlock(modelData.block)
                        }
                    }
                }
            }
        }

        // ── Editor area ───────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 32
            color: "white"; radius: 8
            border.color: "#E5E7EB"; border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Label {
                    text: "@group recomendations"
                    font.pixelSize: 12; font.family: "monospace"; color: "#9CA3AF"
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#F3F4F6" }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    TextArea {
                        id: editor
                        text: controller.recommendations
                        placeholderText: "Рекомендации по настройке и запуску...\n\nнапр.:\nЗапуск аудио драйвера:\n@ul\n@item io-audio -d intel_hda vid=0x8086,did=0x7a50 &\n@endul"
                        wrapMode: TextArea.Wrap
                        font.family: "monospace"; font.pixelSize: 13
                        color: "#374151"
                        background: null
                        topPadding: 0; leftPadding: 0
                        onTextChanged: controller.recommendations = text
                    }
                }
            }
        }

        // ── Footer with save button ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            color: "white"

            Rectangle {
                anchors.top: parent.top
                width: parent.width; height: 1; color: "#E5E7EB"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 32; anchors.rightMargin: 32

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: saveBtnLabel.implicitWidth + 32
                    implicitHeight: 36; radius: 6
                    color: saveBtnHover.containsMouse ? "#1D4ED8" : "#3B82F6"

                    Label {
                        id: saveBtnLabel
                        anchors.centerIn: parent
                        text: "Сохранить и экспортировать TXT"
                        font.pixelSize: 13; font.weight: Font.Medium; color: "white"
                    }

                    HoverHandler { id: saveBtnHover }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (controller.currentFilePath !== "")
                                controller.saveFile()
                            else
                                root.saveAsRequested()
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 0 }
    }

    function insertBlock(block) {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const after  = editor.text.substring(pos)
        editor.text = before + "\n" + block + "\n" + after
        editor.cursorPosition = pos + block.length + 2
    }
}
