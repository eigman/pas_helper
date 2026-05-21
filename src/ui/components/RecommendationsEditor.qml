import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Bctl
import QtQuick.Layouts

// Рекомендации — одно поле; кнопки вставляют строку списка в позицию курсора.
Item {
    id: root

    signal saveAsRequested()

    property bool _updating: false

    readonly property var biosPresetItems: [
        "Advanced -> CPU Configuration -> Intel Hyper Threading Technology -> Disabled",
        "Advanced -> CPU Configuration -> CPU C States Support -> Disabled",
        "Advanced -> CPU Configuration -> Intel Virtualization Technology -> Disabled",
        "Advanced -> CPU Configuration -> Intel SpeedStep Technology -> Disabled",
        "Advanced -> CPU Configuration -> CPU Thermal Throttling -> Disabled",
        "Advanced -> Chipset Configuration -> Above 4G Decoding -> Disabled",
        "Advanced -> Chipset Configuration -> VT-d -> Disabled",
        "Advanced -> Trusted Computing -> Onboard TPM -> Disabled",
        "Security -> Secure Boot -> Secure Boot -> Disabled"
    ]

    function paragraphSep(before) {
        if (before.length === 0)
            return ""
        if (before.endsWith("\n\n"))
            return ""
        if (before.endsWith("\n"))
            return "\n"
        return "\n\n"
    }

    function insertAtCursor(snippet) {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const after = editor.text.substring(pos)
        editor.text = before + snippet + after
        editor.cursorPosition = pos + snippet.length
        editor.forceActiveFocus()
    }

    function lineAtCursor() {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const lineStart = before.lastIndexOf("\n") + 1
        return before.substring(lineStart, pos)
    }

    function nextListNumber() {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const lines = before.split("\n")
        for (let i = lines.length - 1; i >= 0; --i) {
            const t = lines[i].trim()
            if (t === "")
                continue
            const m = t.match(/^(\d+)\.\s/)
            if (m)
                return parseInt(m[1], 10) + 1
            break
        }
        return 1
    }

    // Кнопка: новая строка «1. » (новый список) или продолжение на пустой «N. »
    function insertNumberedList() {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const line = root.lineAtCursor()
        const emptyMarker = /^(\d+)\.\s*$/.exec(line)

        if (emptyMarker) {
            return
        }

        const continueList = /^(\d+)\.\s+.+/.test(line)
        if (continueList) {
            const n = root.nextListNumber()
            insertAtCursor("\n" + n + ". ")
            return
        }

        const sep = root.paragraphSep(before)
        insertAtCursor(sep + "1. ")
    }

    function insertBulletList() {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        const line = root.lineAtCursor()

        if (/^[•\-\*]\s*$/.test(line))
            return

        if (/^[•\-\*]\s+.+/.test(line)) {
            insertAtCursor("\n• ")
            return
        }

        const sep = root.paragraphSep(before)
        insertAtCursor(sep + "• ")
    }

    function insertBiosPreset() {
        const pos = editor.cursorPosition
        const before = editor.text.substring(0, pos)
        let block = "Рекомендуемые настройки BIOS:\n\n"
        for (let i = 0; i < biosPresetItems.length; ++i)
            block += (i + 1) + ". " + biosPresetItems[i] + "\n"
        const sep = root.paragraphSep(before)
        insertAtCursor(sep + block)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 60
            color: "white"

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#E5E7EB"
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.verticalCenter: parent.verticalCenter
                text: "Рекомендации"
                font.pixelSize: 20
                font.weight: Font.Medium
                color: "#111827"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 32
            color: "white"
            radius: 8
            border.color: "#E5E7EB"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: numBtnRow.implicitWidth + 24
                        Layout.preferredHeight: 36
                        radius: 6
                        color: numBtnHover.containsMouse ? "#F3F4F6" : "#F9FAFB"
                        border.color: "#E5E7EB"
                        border.width: 1

                        RowLayout {
                            id: numBtnRow
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: "+"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: "#374151"
                            }
                            Label {
                                text: "Нумерованный пункт"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: "#374151"
                            }
                        }

                        HoverHandler { id: numBtnHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertNumberedList()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: bulBtnRow.implicitWidth + 24
                        Layout.preferredHeight: 36
                        radius: 6
                        color: bulBtnHover.containsMouse ? "#F3F4F6" : "#F9FAFB"
                        border.color: "#E5E7EB"
                        border.width: 1

                        RowLayout {
                            id: bulBtnRow
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: "+"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                color: "#374151"
                            }
                            Label {
                                text: "Маркированный пункт"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: "#374151"
                            }
                        }

                        HoverHandler { id: bulBtnHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertBulletList()
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: biosBtnRow.implicitWidth + 24
                        Layout.preferredHeight: 36
                        radius: 6
                        color: biosBtnHover.containsMouse ? "#F3F4F6" : "#F9FAFB"
                        border.color: "#E5E7EB"
                        border.width: 1

                        RowLayout {
                            id: biosBtnRow
                            anchors.centerIn: parent
                            spacing: 6

                            Label {
                                text: "BIOS"
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                color: "#374151"
                            }
                        }

                        HoverHandler { id: biosBtnHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.insertBiosPreset()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    FieldHelpIcon {
                        Layout.alignment: Qt.AlignVCenter
                        popupSide: "right"
                        popupTitle: ""
                        examples: [
                            "Кнопки «+» вставляют «1. » или «• » в позицию курсора.",
                            "Enter — новый пункт того же списка.",
                            "Shift+Enter — перенос строки внутри пункта.",
                            "Новый список: пустая строка, курсор в неё, снова «+».",
                            "BIOS — готовый нумерованный список настроек."
                        ]
                    }
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Bctl.TextArea {
                        id: editor
                        width: parent.width
                        text: controller.recommendationsText
                        placeholderText: "Текст рекомендаций…"
                        placeholderTextColor: "#94A3B8"
                        wrapMode: TextArea.Wrap
                        font.pixelSize: 14
                        color: "#111827"
                        topPadding: 8
                        leftPadding: 10
                        rightPadding: 10
                        bottomPadding: 8
                        background: Rectangle {
                            color: "#F9FAFB"
                            radius: 6
                            border.color: editor.activeFocus ? "#3B82F6" : "#E5E7EB"
                            border.width: editor.activeFocus ? 1.5 : 1
                        }

                        onTextChanged: {
                            if (root._updating)
                                return
                            controller.recommendationsText = text
                        }

                        Keys.onPressed: function(event) {
                            if (event.key !== Qt.Key_Return || (event.modifiers & Qt.ShiftModifier))
                                return

                            const pos = cursorPosition
                            const lineStart = text.lastIndexOf("\n", pos - 1) + 1
                            const lineEnd = text.indexOf("\n", lineStart)
                            const fullLine = text.substring(lineStart, lineEnd >= 0 ? lineEnd : text.length)

                            const num = fullLine.match(/^(\d+)\.\s(.*)$/)
                            if (num) {
                                event.accepted = true
                                const n = parseInt(num[1], 10) + 1
                                const before = text.substring(0, pos)
                                const after = text.substring(pos)
                                const ins = "\n" + n + ". "
                                editor.text = before + ins + after
                                cursorPosition = pos + ins.length
                                return
                            }

                            const bullet = fullLine.match(/^[•\-\*]\s(.*)$/)
                            if (bullet) {
                                event.accepted = true
                                const before = text.substring(0, pos)
                                const after = text.substring(pos)
                                const ins = "\n• "
                                editor.text = before + ins + after
                                cursorPosition = pos + ins.length
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 56
            color: "white"

            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: "#E5E7EB"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 32
                anchors.rightMargin: 32
                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: saveBtnLabel.implicitWidth + 32
                    implicitHeight: 36
                    radius: 6
                    color: saveBtnHover.containsMouse ? "#1D4ED8" : "#3B82F6"

                    Label {
                        id: saveBtnLabel
                        anchors.centerIn: parent
                        text: "Сохранить и экспортировать TXT"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "white"
                    }
                    HoverHandler { id: saveBtnHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
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
    }

    Connections {
        target: controller
        function onRecommendationsTextChanged() {
            if (editor.activeFocus)
                return
            root._updating = true
            editor.text = controller.recommendationsText
            root._updating = false
        }
    }
}
