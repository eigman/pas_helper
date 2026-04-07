import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Device parameters form — fills @group device first table + OS install section
Item {
    id: root

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: 0

            // ── Page header ───────────────────────────────────────────────────
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
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 32
                    text: "Технические параметры устройства"
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    color: "#111827"
                }
            }

            // ── Device fields ─────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 32
                spacing: 12

                Repeater {
                    model: [
                        { label: "Название устройства", placeholder: "напр. ПК KVADRA TAU",               prop: "devicePageTitle"   },
                        { label: "Модель",              placeholder: "напр. KVADRA TAU",                   prop: "deviceModel"       },
                        { label: "Серийный / Заводской номер", placeholder: "напр. 0310230010",            prop: "deviceSerial"      },
                        { label: "Материнская плата",   placeholder: "напр. KVADRA B760",                  prop: "deviceMotherboard" },
                        { label: "Тип BIOS (версия)",   placeholder: "напр. KVADRA UEFI BIOS Firmware v1.3.1", prop: "deviceBios"   },
                        { label: "Процессор",           placeholder: "напр. Intel Core i5-13400 2.5 GHz",  prop: "deviceProcessor"   },
                        { label: "Чипсет",              placeholder: "напр. Intel B760",                   prop: "deviceChipset"     }
                    ]
                    delegate: DeviceFieldCard {
                        Layout.fillWidth: true
                        fieldLabel: modelData.label
                        fieldPlaceholder: modelData.placeholder
                        fieldValue: controller[modelData.prop]
                        onFieldChanged: function(v) { controller[modelData.prop] = v }
                    }
                }

                // ── RAM card ──────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: ramCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: ramCardContent
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.top: parent.top; anchors.margins: 16
                        spacing: 8

                        Label { text: "ОЗУ"; font.pixelSize: 13; color: "#6B7280" }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8

                            TextField {
                                id: ramField
                                Layout.fillWidth: true
                                text: controller.deviceRam
                                placeholderText: "напр. DDR4 16384 MB"
                                font.pixelSize: 14; color: "#111827"
                                leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                                background: Rectangle {
                                    color: "#F9FAFB"; radius: 6
                                    border.color: ramField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                    border.width: ramField.activeFocus ? 1.5 : 1
                                }
                                onEditingFinished: controller.deviceRam = text
                                Binding {
                                    target: ramField; property: "text"; value: controller.deviceRam
                                    when: !ramField.activeFocus
                                }
                            }

                            RamPickerPopup {
                                id: ramPicker
                                implicitWidth: 70; implicitHeight: 34
                                onSelected: function(v) {
                                    // Append or replace — if field is empty set directly,
                                    // otherwise append a second module
                                    if (ramField.text.trim() === "") {
                                        ramField.text = v
                                    } else {
                                        ramField.text = ramField.text + " / " + v
                                    }
                                    controller.deviceRam = ramField.text
                                }
                            }
                        }
                    }
                }

                // ── Divider ───────────────────────────────────────────────────
                Item { implicitHeight: 8 }

                // ── OS Install section header ─────────────────────────────────
                Label {
                    text: "Установка и запуск ОС"
                    font.pixelSize: 18
                    font.weight: Font.Medium
                    color: "#111827"
                }

                // ── Result toggle ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: resultContent.implicitHeight + 32
                    color: "white"
                    radius: 8
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        id: resultContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            text: "Результат"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }

                        ResultToggle {
                            Layout.fillWidth: true
                            currentValue: controller.osTestResult
                            onValueChanged: function(v) { controller.osTestResult = v }

                            Connections {
                                target: controller
                                function onOsInstallChanged() {
                                    // binding refreshes automatically
                                }
                            }
                        }
                    }
                }

                // ── Note card ─────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: noteContent.implicitHeight + 32
                    color: "white"
                    radius: 8
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        id: noteContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8

                        Label {
                            text: "Примечание"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }

                        TextArea {
                            id: osNoteArea
                            Layout.fillWidth: true
                            implicitHeight: 72
                            text: controller.osTestNote
                            placeholderText: "напр. Установка с USB Flash"
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 14
                            color: "#111827"
                            topPadding: 8
                            leftPadding: 8
                            rightPadding: 8
                            bottomPadding: 8
                            background: Rectangle {
                                color: "#F9FAFB"
                                radius: 6
                                border.color: osNoteArea.activeFocus ? "#3B82F6" : "#E5E7EB"
                                border.width: osNoteArea.activeFocus ? 1.5 : 1
                            }
                            onEditingFinished: controller.osTestNote = text

                            Connections {
                                target: controller
                                function onOsInstallChanged() { osNoteArea.text = controller.osTestNote }
                            }
                        }
                    }
                }

                // ── Check items card ──────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: checksContent.implicitHeight + 32
                    color: "white"
                    radius: 8
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        id: checksContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 0

                        Label {
                            text: "Перечень проверок"
                            font.pixelSize: 13
                            color: "#6B7280"
                            Layout.bottomMargin: 12
                        }

                        // Existing check items
                        Repeater {
                            id: osChecksRepeater
                            model: controller.osCheckItems

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 44
                                color: "white"

                                Rectangle {
                                    anchors.top: parent.top
                                    width: parent.width; height: 1; color: "#F3F4F6"
                                    visible: index > 0
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4; anchors.rightMargin: 8
                                    spacing: 8

                                    Label {
                                        text: index + 1
                                        font.pixelSize: 13; color: "#9CA3AF"
                                        Layout.preferredWidth: 20
                                        horizontalAlignment: Text.AlignRight
                                    }

                                    TextField {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.pixelSize: 14; color: "#111827"
                                        background: null; leftPadding: 0
                                        onEditingFinished: controller.setOsCheckItem(index, text)
                                    }

                                    Rectangle {
                                        width: 24; height: 24; radius: 4
                                        color: osRemoveHover.containsMouse ? "#FEE2E2" : "transparent"
                                        Label {
                                            anchors.centerIn: parent; text: "×"; font.pixelSize: 16
                                            color: osRemoveHover.containsMouse ? "#DC2626" : "#9CA3AF"
                                        }
                                        HoverHandler { id: osRemoveHover }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: controller.removeOsCheckItem(index)
                                        }
                                    }
                                }
                            }
                        }

                        // Add check item row
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            color: addCheckHover.containsMouse ? "#F9FAFB" : "white"
                            radius: 6
                            border.color: "#D1D5DB"
                            border.width: 1
                            Layout.topMargin: osChecksRepeater.count > 0 ? 8 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Label {
                                    text: "+"
                                    font.pixelSize: 16
                                    color: "#6B7280"
                                }

                                TextField {
                                    id: osCheckField
                                    Layout.fillWidth: true
                                    placeholderText: "Добавить пункт..."
                                    font.pixelSize: 14
                                    background: null
                                    leftPadding: 0
                                    onAccepted: root.addOsCheck()
                                }

                                PresetPickerPopup {
                                    implicitWidth: 110; implicitHeight: 34
                                    presets: controller.osInstallChecksPresets()
                                    onSelected: function(v) { controller.addOsCheckItem(v) }
                                }
                            }

                            HoverHandler { id: addCheckHover }
                        }
                    }
                }

                Item { implicitHeight: 24 }
            }
        }
    }

    function addOsCheck() {
        const text = osCheckField.text.trim()
        if (text !== "") {
            controller.addOsCheckItem(text)
            osCheckField.text = ""
        }
    }
}
