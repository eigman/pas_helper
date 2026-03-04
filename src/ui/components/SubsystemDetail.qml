import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Detail panel for a selected subsystem.
// All changes written back via controller.subsystemModel.setField()
ScrollView {
    id: root

    property int subsystemIndex: -1

    // Emitted when user clicks "Open PCI Analyser" — connected in SubsystemsPage
    signal openPciRequested()

    clip: true

    // Reload all fields when selection changes or model data updates
    function reload() {
        if (subsystemIndex < 0) return
        const s = controller.subsystemModel.getSubsystem(subsystemIndex)
        nameField.text      = s["name"]        || ""
        controllerArea.text = s["controller"]  || ""
        ifaceField.text     = s["interfaces"]  || ""
        driverField.text    = s["driver"]      || ""
        noteField.text      = s["testNote"]    || ""
        hintArea.text       = s["hintText"]    || ""
        cautionArea.text    = s["cautionText"] || ""
        hintCheck.checked   = (s["hintText"]    || "") !== ""
        cautionCheck.checked = (s["cautionText"] || "") !== ""

        const opts = controller.testResultOptions()
        const ri = opts.indexOf(s["testResult"] || "успешно")
        resultCombo.currentIndex = ri >= 0 ? ri : 0
    }

    onSubsystemIndexChanged: reload()

    Connections {
        target: controller.subsystemModel
        function onDataChanged() { root.reload() }
    }

    ColumnLayout {
        width: root.width
        spacing: 0

        // ── Header ───────────────────────────────────────────────────────
        Pane {
            Layout.fillWidth: true
            Material.elevation: 1
            padding: 12

            Label {
                text: nameField.text || "Подсистема"
                font.pixelSize: 16
                font.bold: true
            }
        }

        // ── Basic fields ─────────────────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            columns: 2
            rowSpacing: 10
            columnSpacing: 16

            // Name
            Label { text: "Название"; opacity: 0.8 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                TextField {
                    id: nameField
                    Layout.fillWidth: true
                    placeholderText: "напр. Дисковая \\n подсистема"
                    onEditingFinished: controller.subsystemModel.setField(
                        root.subsystemIndex, "name", text)
                }
                Label {
                    text: "(\\n = перенос в таблице)"
                    font.pixelSize: 10
                    opacity: 0.45
                }
            }

            // Controller
            Label { text: "Контроллер"; opacity: 0.8; verticalAlignment: Label.AlignTop; topPadding: 6 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                TextArea {
                    id: controllerArea
                    Layout.fillWidth: true
                    placeholderText: "напр. Raptor Lake SATA AHCI Controller \\n[**8086:7a62**]\nили '-' если нет контроллера"
                    wrapMode: TextArea.Wrap
                    implicitHeight: 56
                    onEditingFinished: controller.subsystemModel.setField(
                        root.subsystemIndex, "controller", text)
                }

                Button {
                    text: "Открыть PCI анализатор →"
                    flat: true
                    font.pixelSize: 11
                    Material.accent: Material.Teal
                    onClicked: root.openPciRequested()
                }
            }

            // Interfaces
            Label { text: "Интерфейс(ы)"; opacity: 0.8 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                TextField {
                    id: ifaceField
                    Layout.fillWidth: true
                    placeholderText: "напр. Serial ATA  или  1x HDMI \\n 1x VGA"
                    onEditingFinished: controller.subsystemModel.setField(
                        root.subsystemIndex, "interfaces", text)
                }
                ComboBox {
                    model: controller.interfacePresets()
                    displayText: "Пресеты"
                    implicitWidth: 110
                    onActivated: {
                        ifaceField.text = ifaceField.text !== ""
                            ? ifaceField.text + " \\n " + currentText
                            : currentText
                        ifaceField.editingFinished()
                    }
                }
            }

            // Driver
            Label { text: "Драйвер"; opacity: 0.8 }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                TextField {
                    id: driverField
                    Layout.fillWidth: true
                    placeholderText: "напр. devb-ahci"
                    onEditingFinished: controller.subsystemModel.setField(
                        root.subsystemIndex, "driver", text)
                }
                ComboBox {
                    model: controller.driverPresets()
                    displayText: "Пресеты"
                    implicitWidth: 110
                    onActivated: {
                        driverField.text = currentText
                        driverField.editingFinished()
                    }
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            implicitHeight: 1
            color: "#40ffffff"
        }

        // ── Test section header ───────────────────────────────────────────
        Pane {
            Layout.fillWidth: true
            padding: 12

            Label {
                text: "Тестирование"
                font.bold: true
                font.pixelSize: 14
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 16
            columns: 2
            rowSpacing: 10
            columnSpacing: 16

            // Check items list
            Label { text: "Перечень проверок"; opacity: 0.8; verticalAlignment: Label.AlignTop; topPadding: 6 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    id: checksRepeater
                    model: {
                        if (root.subsystemIndex < 0) return []
                        return controller.subsystemModel.getSubsystem(root.subsystemIndex)["checkItems"] || []
                    }

                    RowLayout {
                        width: parent ? parent.width : 0
                        spacing: 4
                        Label {
                            text: (index + 1) + "."
                            opacity: 0.5
                            Layout.preferredWidth: 20
                        }
                        TextField {
                            Layout.fillWidth: true
                            text: modelData
                            background: null
                            onEditingFinished: {
                                const items = checksRepeater.model.slice()
                                items[index] = text
                                controller.subsystemModel.setCheckItems(root.subsystemIndex, items)
                            }
                        }
                        ToolButton {
                            text: "✕"
                            font.pixelSize: 11
                            opacity: 0.5
                            onClicked: controller.subsystemModel.removeCheckItem(
                                root.subsystemIndex, index)
                        }
                    }
                }

                // Add new check item
                RowLayout {
                    spacing: 6
                    TextField {
                        id: checkField
                        placeholderText: "Добавить пункт..."
                        Layout.preferredWidth: 280
                        onAccepted: root.addCheck()
                    }
                    Button { text: "+"; flat: true; onClicked: root.addCheck() }
                    ComboBox {
                        model: {
                            if (root.subsystemIndex < 0) return []
                            const name = controller.subsystemModel.getSubsystem(root.subsystemIndex)["name"] || ""
                            return controller.checksPresets(name)
                        }
                        displayText: "Пресеты"
                        implicitWidth: 110
                        onActivated: controller.subsystemModel.addCheckItem(
                            root.subsystemIndex, currentText)
                    }
                }
            }

            // Result
            Label { text: "Результат"; opacity: 0.8 }
            ComboBox {
                id: resultCombo
                model: controller.testResultOptions()
                onActivated: controller.subsystemModel.setField(
                    root.subsystemIndex, "testResult", currentText)
            }

            // Note
            Label { text: "Примечание"; opacity: 0.8 }
            TextField {
                id: noteField
                Layout.fillWidth: true
                placeholderText: "Примечание для итоговой таблицы"
                onEditingFinished: controller.subsystemModel.setField(
                    root.subsystemIndex, "testNote", text)
            }

            // @hint
            Label { text: "@hint"; opacity: 0.8 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                CheckBox {
                    id: hintCheck
                    text: "Добавить замечание (@hint)"
                    onToggled: if (!checked) {
                        hintArea.text = ""
                        controller.subsystemModel.setField(root.subsystemIndex, "hintText", "")
                    }
                }
                TextArea {
                    id: hintArea
                    visible: hintCheck.checked
                    Layout.fillWidth: true
                    placeholderText: "Текст замечания..."
                    wrapMode: TextArea.Wrap
                    implicitHeight: 56
                    onEditingFinished: controller.subsystemModel.setField(
                        root.subsystemIndex, "hintText", text)
                }
            }

            // @caution
            Label { text: "@caution"; opacity: 0.8 }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4
                CheckBox {
                    id: cautionCheck
                    text: "Добавить предупреждение (@caution)"
                    onToggled: if (!checked) {
                        cautionArea.text = ""
                        controller.subsystemModel.setField(root.subsystemIndex, "cautionText", "")
                    }
                }
                TextArea {
                    id: cautionArea
                    visible: cautionCheck.checked
                    Layout.fillWidth: true
                    placeholderText: "Текст предупреждения..."
                    wrapMode: TextArea.Wrap
                    implicitHeight: 56
                    onEditingFinished: controller.subsystemModel.setField(
                        root.subsystemIndex, "cautionText", text)
                }
            }
        }

        Item { implicitHeight: 24 }
    }

    function addCheck() {
        if (checkField.text.trim() !== "") {
            controller.subsystemModel.addCheckItem(root.subsystemIndex, checkField.text)
            checkField.text = ""
        }
    }
}
