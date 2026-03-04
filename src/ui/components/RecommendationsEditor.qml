import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Recommendations editor — free text with @ul / @ol helper buttons
Item {
    id: root

    signal saveAsRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Header + toolbar
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "@group recomendations"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            // Quick insert buttons
            Label { text: "Вставить:"; opacity: 0.7; font.pixelSize: 12 }

            Button {
                text: "@ul список"
                flat: true
                font.pixelSize: 11
                onClicked: insertBlock("@ul\n@item \n@endul\n")
            }

            Button {
                text: "@ol нумерованный"
                flat: true
                font.pixelSize: 11
                onClicked: insertBlock("@ol\n@item \n@endol\n")
            }

            Button {
                text: "@hint"
                flat: true
                font.pixelSize: 11
                onClicked: insertBlock("@hint\n\n@endhint\n")
            }

            Button {
                text: "@caution"
                flat: true
                font.pixelSize: 11
                onClicked: insertBlock("@caution\n\n@endcaution\n")
            }
        }

        // Help text
        Label {
            text: "Используйте @ul/@endul для списков, @ol/@endol для нумерованных, @hint/@caution для блоков."
            font.pixelSize: 11
            opacity: 0.5
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Text editor
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            TextArea {
                id: editor
                text: controller.recommendations
                placeholderText: "Рекомендации по настройке и запуску...\n\nнапр.:\nЗапуск аудио драйвера:\n@ul\n@item io-audio -d intel_hda vid=0x8086,did=0x7a50 &\n@endul"
                wrapMode: TextArea.Wrap
                font.family: "monospace"
                font.pixelSize: 13
                onTextChanged: controller.recommendations = text
            }
        }

        // Export button
        RowLayout {
            Layout.fillWidth: true

            Item { Layout.fillWidth: true }

            Button {
                text: "Сохранить и экспортировать TXT"
                highlighted: true
                Material.accent: Material.Teal
                    onClicked: {
                        if (controller.currentFilePath !== "")
                            controller.saveFile()
                        else
                            root.saveAsRequested()
                    }
            }
        }
    }

    function insertBlock(block) {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const after  = editor.text.substring(pos)
        editor.text = before + "\n" + block + "\n" + after
        editor.cursorPosition = pos + block.length + 2
    }
}
