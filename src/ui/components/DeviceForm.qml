import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Device parameters form — fills @group device first table + OS install section
ScrollView {
    id: root
    clip: true

    ColumnLayout {
        width: root.width
        spacing: 0

        // Section header
        Pane {
            Layout.fillWidth: true
            Material.elevation: 2

            RowLayout {
                anchors.fill: parent
                Label {
                    text: "Технические параметры устройства"
                    font.pixelSize: 16
                    font.bold: true
                    Layout.fillWidth: true
                }
                Label {
                    text: controller.devicePageTitle !== "" ? controller.devicePageTitle : "Новый отчёт"
                    font.pixelSize: 13
                    opacity: 0.7
                }
            }
        }

        // Device fields
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 24
            columns: 2
            rowSpacing: 8
            columnSpacing: 16

            Label { text: "Название устройства"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. ПК KVADRA TAU"
                text: controller.devicePageTitle
                onEditingFinished: controller.devicePageTitle = text
            }

            Label { text: "Модель"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. KVADRA TAU"
                text: controller.deviceModel
                onEditingFinished: controller.deviceModel = text
            }

            Label { text: "Серийный / Заводской номер"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. 0310230010"
                text: controller.deviceSerial
                onEditingFinished: controller.deviceSerial = text
            }

            Label { text: "Материнская плата"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. KVADRA B760"
                text: controller.deviceMotherboard
                onEditingFinished: controller.deviceMotherboard = text
            }

            Label { text: "Тип BIOS (версия)"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. KVADRA UEFI BIOS Firmware v1.3.1"
                text: controller.deviceBios
                onEditingFinished: controller.deviceBios = text
            }

            Label { text: "Процессор"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. Intel Core i5-13400 2.5 GHz"
                text: controller.deviceProcessor
                onEditingFinished: controller.deviceProcessor = text
            }

            Label { text: "Чипсет"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. Intel B760"
                text: controller.deviceChipset
                onEditingFinished: controller.deviceChipset = text
            }

            Label { text: "ОЗУ"; opacity: 0.8 }
            TextField {
                Layout.fillWidth: true
                placeholderText: "напр. DDR4 16384 MB"
                text: controller.deviceRam
                onEditingFinished: controller.deviceRam = text
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            implicitHeight: 1
            color: "#40ffffff"
        }

        // OS Install section
        Pane {
            Layout.fillWidth: true
            Layout.topMargin: 8
            padding: 16

            Label {
                text: "Установка и запуск ОС"
                font.pixelSize: 16
                font.bold: true
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 24
            columns: 2
            rowSpacing: 8
            columnSpacing: 16

            Label { text: "Результат"; opacity: 0.8 }
            ComboBox {
                id: osResultCombo
                model: controller.testResultOptions()
                currentIndex: {
                    const opts = controller.testResultOptions()
                    const idx = opts.indexOf(controller.osTestResult)
                    return idx >= 0 ? idx : 0
                }
                onActivated: controller.osTestResult = currentText

                Connections {
                    target: controller
                    function onOsInstallChanged() {
                        const opts = controller.testResultOptions()
                        const idx = opts.indexOf(controller.osTestResult)
                        osResultCombo.currentIndex = idx >= 0 ? idx : 0
                    }
                }
            }

            Label { text: "Примечание"; opacity: 0.8 }
            TextField {
                id: osNoteField
                Layout.fillWidth: true
                placeholderText: "напр. Установка с USB Flash"
                text: controller.osTestNote
                onEditingFinished: controller.osTestNote = text

                Connections {
                    target: controller
                    function onOsInstallChanged() { osNoteField.text = controller.osTestNote }
                }
            }

            Label {
                text: "Перечень проверок"
                opacity: 0.8
                verticalAlignment: Label.AlignTop
                topPadding: 8
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Existing check items
                Repeater {
                    id: osChecksRepeater
                    model: controller.osCheckItems

                    RowLayout {
                        width: parent.width
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
                            onEditingFinished: controller.setOsCheckItem(index, text)
                        }

                        ToolButton {
                            text: "✕"
                            font.pixelSize: 11
                            opacity: 0.5
                            onClicked: controller.removeOsCheckItem(index)
                        }
                    }
                }

                // Add new check item row
                RowLayout {
                    spacing: 8

                    TextField {
                        id: osCheckField
                        Layout.preferredWidth: 300
                        placeholderText: "Добавить пункт..."
                        onAccepted: root.addOsCheck()
                    }

                    Button {
                        text: "+"
                        flat: true
                        onClicked: root.addOsCheck()
                    }

                    ComboBox {
                        model: controller.osInstallChecksPresets()
                        displayText: "Из пресетов"
                        implicitWidth: 140
                        onActivated: controller.addOsCheckItem(currentText)
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 24 }
    }

    // Adds a new OS check item from the text field
    function addOsCheck() {
        const text = osCheckField.text.trim()
        if (text !== "") {
            controller.addOsCheckItem(text)
            osCheckField.text = ""
        }
    }
}
