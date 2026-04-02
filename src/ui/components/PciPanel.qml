import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// PCI Analyzer panel — paste pci -vvv dump, parse it, assign devices to subsystems
Item {
    id: root

    signal assignToSubsystem(int pciIndex, int subsystemIndex)

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: "#E5E7EB"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Header ────────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Image {
                source: "qrc:/resources/icons/pci.svg"
                width: 18; height: 18; opacity: 0.6
            }

            Label {
                text: "PCI Анализатор"
                font.pixelSize: 16
                font.weight: Font.Medium
                color: "#111827"
                Layout.fillWidth: true
            }

            Label {
                text: controller.pciStatusMessage
                font.pixelSize: 11
                color: controller.pciIdsLoaded ? "#16A34A" : "#D97706"
                wrapMode: Text.Wrap
            }
        }

        // ── Dump input card ───────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: dumpCardContent.implicitHeight + 32
            color: "white"; radius: 8
            border.color: "#E5E7EB"; border.width: 1

            ColumnLayout {
                id: dumpCardContent
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                spacing: 10

                Label {
                    text: "Вставьте вывод pci -vvv"
                    font.pixelSize: 13; color: "#6B7280"
                }

                TextArea {
                    id: dumpArea
                    Layout.fillWidth: true
                    implicitHeight: 140
                    placeholderText: "Class          = Mass Storage (Serial ATA)\nVendor ID      = 8086h, Intel Corporation\nDevice ID      = 7a62h, Unknown Unknown\n..."
                    wrapMode: TextArea.Wrap
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: "#374151"
                    topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                    background: Rectangle {
                        color: "#F9FAFB"; radius: 6
                        border.color: dumpArea.activeFocus ? "#3B82F6" : "#E5E7EB"
                        border.width: dumpArea.activeFocus ? 1.5 : 1
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    Rectangle {
                        implicitWidth: parseLabel.implicitWidth + 24
                        implicitHeight: 34
                        radius: 6
                        color: dumpArea.text.trim() !== "" ? "#3B82F6" : "#E5E7EB"

                        Label {
                            id: parseLabel
                            anchors.centerIn: parent
                            text: "Разобрать"
                            font.pixelSize: 13; font.weight: Font.Medium
                            color: dumpArea.text.trim() !== "" ? "white" : "#9CA3AF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: dumpArea.text.trim() !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: dumpArea.text.trim() !== ""
                            onClicked: controller.parsePciDump(dumpArea.text)
                        }
                    }

                    Rectangle {
                        implicitWidth: clearLabel.implicitWidth + 20
                        implicitHeight: 34
                        radius: 6
                        color: clearHover.containsMouse ? "#F3F4F6" : "transparent"
                        border.color: "#E5E7EB"; border.width: 1

                        Label {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Очистить"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }

                        HoverHandler { id: clearHover }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: dumpArea.text = ""
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: controller.pciModel.count + " устр."
                        visible: controller.pciModel.count > 0
                        font.pixelSize: 12; color: "#6B7280"
                    }
                }
            }
        }

        // ── Devices list ──────────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"; radius: 8
            border.color: "#E5E7EB"; border.width: 1
            visible: controller.pciModel.count > 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Label {
                    text: "Найденные устройства"
                    font.pixelSize: 13; color: "#6B7280"
                }

                // Subsystem assignment selector
                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    Label {
                        text: "Назначить в:"
                        font.pixelSize: 13; color: "#374151"
                    }

                    ComboBox {
                        id: targetSubsystemCombo
                        Layout.fillWidth: true
                        font.pixelSize: 13
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

                // Devices
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: deviceList
                        model: controller.pciModel
                        spacing: 8

                        delegate: Rectangle {
                            width: deviceList.width
                            implicitHeight: devContent.implicitHeight + 24
                            color: "#F9FAFB"; radius: 6
                            border.color: "#E5E7EB"; border.width: 1

                            ColumnLayout {
                                id: devContent
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true; spacing: 8

                                    // Class badge
                                    Rectangle {
                                        implicitWidth: classBadge.implicitWidth + 10
                                        implicitHeight: 20; radius: 4
                                        color: "#EFF6FF"

                                        Label {
                                            id: classBadge
                                            anchors.centerIn: parent
                                            text: model.classStr
                                            font.pixelSize: 10; color: "#1D4ED8"
                                        }
                                    }

                                    Label {
                                        text: model.vendorId + ":" + model.deviceId
                                        font.family: "monospace"; font.pixelSize: 11
                                        color: "#6B7280"
                                    }

                                    Item { Layout.fillWidth: true }

                                    Label {
                                        visible: model.suggestedSubsystem !== ""
                                        text: "→ " + model.suggestedSubsystem.replace(/\\n/g, ' ')
                                        font.pixelSize: 10; color: "#3B82F6"
                                    }
                                }

                                Label {
                                    text: model.deviceName !== ""
                                          ? model.deviceName
                                          : "(название не найдено — " + model.vendorName + ")"
                                    font.pixelSize: 13; color: "#111827"
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    implicitWidth: insertLabel.implicitWidth + 20
                                    implicitHeight: 28; radius: 6
                                    color: targetSubsystemCombo.currentIndex > 0
                                           ? (insertHover.containsMouse ? "#DBEAFE" : "#EFF6FF")
                                           : "#F3F4F6"
                                    border.color: targetSubsystemCombo.currentIndex > 0 ? "#BFDBFE" : "#E5E7EB"
                                    border.width: 1

                                    Label {
                                        id: insertLabel
                                        anchors.centerIn: parent
                                        text: "Вставить в подсистему"
                                        font.pixelSize: 11
                                        color: targetSubsystemCombo.currentIndex > 0 ? "#1D4ED8" : "#9CA3AF"
                                    }

                                    HoverHandler { id: insertHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: targetSubsystemCombo.currentIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
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
        }

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: controller.pciModel.count === 0

            Label {
                anchors.centerIn: parent
                text: "Вставьте вывод pci -vvv\nи нажмите «Разобрать»"
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14; color: "#9CA3AF"
                wrapMode: Text.Wrap
            }
        }
    }
}
