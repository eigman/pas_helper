import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// PCI Analyzer panel — paste pci -vvv dump, parse it, assign devices to subsystems
Item {
    id: root

    signal assignToSubsystem(int pciIndex, int subsystemIndex)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Label {
            text: "PCI Анализатор"
            font.pixelSize: 16
            font.bold: true
        }

        // Status
        Label {
            text: controller.pciStatusMessage
            font.pixelSize: 11
            color: controller.pciIdsLoaded
                   ? Material.color(Material.Green)
                   : Material.color(Material.Orange)
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        // Dump input
        GroupBox {
            title: "Вставьте вывод pci -vvv"
            Layout.fillWidth: true
            Layout.preferredHeight: 180

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TextArea {
                        id: dumpArea
                        placeholderText: "Вставьте сюда вывод команды pci -vvv с целевой машины...\n\nClass          = Mass Storage (Serial ATA)\nVendor ID      = 8086h, Intel Corporation\nDevice ID      = 7a62h, Unknown Unknown\n..."
                        wrapMode: TextArea.Wrap
                        font.family: "monospace"
                        font.pixelSize: 11
                    }
                }

                RowLayout {
                    Button {
                        text: "Разобрать"
                        Material.accent: Material.Teal
                        highlighted: true
                        enabled: dumpArea.text.trim() !== ""
                        onClicked: {
                            controller.parsePciDump(dumpArea.text)
                        }
                    }
                    Button {
                        text: "Очистить"
                        flat: true
                        onClicked: dumpArea.text = ""
                    }
                    Label {
                        text: controller.pciModel.count + " устр."
                        visible: controller.pciModel.count > 0
                        opacity: 0.7
                        font.pixelSize: 12
                    }
                }
            }
        }

        // Parsed devices list
        GroupBox {
            title: "Найденные устройства"
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: controller.pciModel.count > 0

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                // Subsystem selector for assignment
                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Назначить в:"; opacity: 0.8 }
                    ComboBox {
                        id: targetSubsystemCombo
                        Layout.fillWidth: true
                        model: {
                            let names = ["— выбрать подсистему —"]
                            for (let i = 0; i < controller.subsystemModel.count; i++) {
                                const idx = controller.subsystemModel.index(i, 0)
                                const name = controller.subsystemModel.data(idx, 257)
                                names.push(name.replace(/\\n/g, ' '))
                            }
                            return names
                        }
                    }
                }

                // Devices list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: deviceList
                        model: controller.pciModel
                        spacing: 4

                        delegate: Pane {
                            width: deviceList.width
                            padding: 8
                            Material.elevation: 1

                            ColumnLayout {
                                width: parent.width - 16
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true

                                    // Class badge
                                    Rectangle {
                                        implicitWidth: classLabel.implicitWidth + 8
                                        implicitHeight: 18
                                        radius: 3
                                        color: Material.color(Material.Teal, Material.Shade800)
                                        Label {
                                            id: classLabel
                                            anchors.centerIn: parent
                                            text: model.classStr
                                            font.pixelSize: 10
                                        }
                                    }

                                    Label {
                                        text: model.vendorId + ":" + model.deviceId
                                        font.family: "monospace"
                                        font.pixelSize: 11
                                        opacity: 0.6
                                    }

                                    Item { Layout.fillWidth: true }

                                    // Suggested subsystem chip
                                    Label {
                                        visible: model.suggestedSubsystem !== ""
                                        text: "→ " + model.suggestedSubsystem.replace(/\\n/g, ' ')
                                        font.pixelSize: 10
                                        color: Material.color(Material.Teal)
                                    }
                                }

                                Label {
                                    text: model.deviceName !== ""
                                          ? model.deviceName
                                          : "(название не найдено — " + model.vendorName + ")"
                                    font.pixelSize: 12
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                Button {
                                    text: "Вставить в подсистему"
                                    flat: true
                                    font.pixelSize: 11
                                    Material.accent: Material.Teal
                                    enabled: targetSubsystemCombo.currentIndex > 0
                                    onClicked: {
                                        const subIdx = targetSubsystemCombo.currentIndex - 1
                                        root.assignToSubsystem(index, subIdx)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Empty state when nothing parsed
        Label {
            visible: controller.pciModel.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Вставьте вывод pci -vvv\nи нажмите «Разобрать»"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            opacity: 0.3
            wrapMode: Text.Wrap
        }
    }
}
