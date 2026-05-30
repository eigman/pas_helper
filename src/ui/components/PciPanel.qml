import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// PCI Analyzer panel — paste pci -vvv dump, parse it, assign devices to subsystems
Item {
    id: root

    signal assignToSubsystem(int pciIndex, int subsystemIndex)
    property int lastAssignedPciIndex: -1
    property string lastAssignedSubsystem: ""
    property string usedQuickAssignTokens: ""

    function normalizeSubsystemName(name) {
        return (name || "")
            .replace(/ ?\\n ?/g, " ")
            .replace(/\s+/g, " ")
            .trim()
            .toLowerCase()
    }

    function findSubsystemIndexByName(name) {
        const target = normalizeSubsystemName(name)
        if (target === "")
            return -1

        for (let i = 0; i < controller.subsystemModel.count; i++) {
            const idx = controller.subsystemModel.index(i, 0)
            const modelName = controller.subsystemModel.data(idx, 257)
            if (normalizeSubsystemName(modelName) === target)
                return i
        }
        return -1
    }

    function quickAssignToken(pciIndex, vendorId, deviceId) {
        return "|" + pciIndex + ":" + vendorId + ":" + deviceId + "|"
    }

    function isQuickAssignUsed(pciIndex, vendorId, deviceId) {
        const token = quickAssignToken(pciIndex, vendorId, deviceId)
        return usedQuickAssignTokens.indexOf(token) >= 0
    }

    function markQuickAssignUsed(pciIndex, vendorId, deviceId) {
        const token = quickAssignToken(pciIndex, vendorId, deviceId)
        if (usedQuickAssignTokens.indexOf(token) < 0)
            usedQuickAssignTokens += token
    }

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
                    placeholderText: ""
                    wrapMode: TextArea.Wrap
                    font.family: "monospace"
                    font.pixelSize: 11
                    color: "#374151"
                    topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                    background: Rectangle {
                        color: "#F9FAFB"; radius: 6
                        border.color: dumpArea.activeFocus ? "#0EA5E9" : "#E5E7EB"
                        border.width: dumpArea.activeFocus ? 1.5 : 1
                    }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 8

                    Rectangle {
                        implicitWidth: parseLabel.implicitWidth + 24
                        implicitHeight: 34
                        radius: 6
                        color: dumpArea.text.trim() !== "" ? "#0EA5E9" : "#E5E7EB"

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
                            onClicked: {
                                root.usedQuickAssignTokens = ""
                                root.lastAssignedPciIndex = -1
                                root.lastAssignedSubsystem = ""
                                controller.parsePciDump(dumpArea.text)
                            }
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
                        implicitHeight: 36
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

                        leftPadding: 12
                        rightPadding: 30

                        contentItem: Text {
                            text: targetSubsystemCombo.displayText
                            color: targetSubsystemCombo.currentIndex > 0 ? "#111827" : "#9CA3AF"
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        background: Rectangle {
                            color: "#F9FAFB"
                            radius: 6
                            border.color: targetSubsystemCombo.activeFocus ? "#0EA5E9" : "#E5E7EB"
                            border.width: targetSubsystemCombo.activeFocus ? 1.5 : 1
                        }

                        indicator: Canvas {
                            x: targetSubsystemCombo.width - width - 10
                            y: (targetSubsystemCombo.height - height) / 2
                            width: 12
                            height: 8
                            contextType: "2d"
                            onPaint: {
                                context.reset()
                                context.moveTo(0, 0)
                                context.lineTo(width, 0)
                                context.lineTo(width / 2, height)
                                context.closePath()
                                context.fillStyle = "#6B7280"
                                context.fill()
                            }
                        }

                        popup: Popup {
                            y: targetSubsystemCombo.height + 4
                            width: targetSubsystemCombo.width
                            padding: 4

                            background: Rectangle {
                                color: "white"
                                radius: 8
                                border.color: "#E5E7EB"
                                border.width: 1
                            }

                            contentItem: ListView {
                                clip: true
                                implicitHeight: Math.min(contentHeight, 280)
                                model: targetSubsystemCombo.popup.visible ? targetSubsystemCombo.delegateModel : null
                                currentIndex: targetSubsystemCombo.highlightedIndex
                                ScrollIndicator.vertical: ScrollIndicator {}
                            }
                        }

                        delegate: ItemDelegate {
                            required property var modelData
                            required property int index
                            width: targetSubsystemCombo.width - 8
                            height: 34
                            text: modelData
                            font.pixelSize: 13
                            leftPadding: 10
                            rightPadding: 10
                            highlighted: targetSubsystemCombo.highlightedIndex === index

                            background: Rectangle {
                                radius: 6
                                color: parent.highlighted
                                       ? "#E0F2FE"
                                       : (parent.hovered ? "#F3F4F6" : "transparent")
                            }

                            contentItem: Text {
                                text: parent.text
                                font: parent.font
                                color: parent.index === 0 ? "#9CA3AF" : "#111827"
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                Label {
                    Layout.fillWidth: true
                    visible: assignFeedbackTimer.running && root.lastAssignedSubsystem !== ""
                    text: "Добавлено в: " + root.lastAssignedSubsystem
                    font.pixelSize: 12
                    color: "#16A34A"
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
                                        color: "#E0F2FE"

                                        Label {
                                            id: classBadge
                                            anchors.centerIn: parent
                                            text: model.classStr
                                            font.pixelSize: 10; color: "#0284C7"
                                        }
                                    }

                                    Label {
                                        text: model.vendorId + ":" + model.deviceId
                                        font.family: "monospace"; font.pixelSize: 11
                                        color: "#6B7280"
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        visible: model.suggestedSubsystem !== ""
                                        implicitWidth: suggestedLinkLabel.implicitWidth + 8
                                        implicitHeight: suggestedLinkLabel.implicitHeight + 4
                                        Layout.alignment: Qt.AlignVCenter
                                        color: "transparent"
                                        radius: 4

                                        readonly property int suggestedIndex: root.findSubsystemIndexByName(model.suggestedSubsystem)
                                        readonly property bool quickAssignAvailable:
                                            suggestedIndex >= 0 && !root.isQuickAssignUsed(index, model.vendorId, model.deviceId)

                                        Label {
                                            id: suggestedLinkLabel
                                            anchors.centerIn: parent
                                            text: "→ " + model.suggestedSubsystem.replace(/\\n/g, ' ')
                                            font.pixelSize: 10
                                            color: parent.quickAssignAvailable ? "#2563EB" : "#9CA3AF"
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: parent.quickAssignAvailable
                                            cursorShape: parent.quickAssignAvailable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                root.assignToSubsystem(index, parent.suggestedIndex)
                                                root.markQuickAssignUsed(index, model.vendorId, model.deviceId)
                                                root.lastAssignedPciIndex = index
                                                root.lastAssignedSubsystem = model.suggestedSubsystem.replace(/\\n/g, " ")
                                                assignFeedbackTimer.restart()
                                            }
                                        }
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
                                           ? (insertHover.containsMouse ? "#BAE6FD" : "#E0F2FE")
                                           : "#F3F4F6"
                                    border.color: targetSubsystemCombo.currentIndex > 0 ? "#BAE6FD" : "#E5E7EB"
                                    border.width: 1

                                    Label {
                                        id: insertLabel
                                        anchors.centerIn: parent
                                        text: root.lastAssignedPciIndex === index && assignFeedbackTimer.running
                                              ? "Добавлено"
                                              : "Вставить в подсистему"
                                        font.pixelSize: 11
                                        color: root.lastAssignedPciIndex === index && assignFeedbackTimer.running
                                               ? "#15803D"
                                               : (targetSubsystemCombo.currentIndex > 0 ? "#0284C7" : "#9CA3AF")
                                    }

                                    HoverHandler { id: insertHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: targetSubsystemCombo.currentIndex > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        enabled: targetSubsystemCombo.currentIndex > 0
                                        onClicked: {
                                            const subIdx = targetSubsystemCombo.currentIndex - 1
                                            root.assignToSubsystem(index, subIdx)
                                            root.lastAssignedPciIndex = index
                                            root.lastAssignedSubsystem = targetSubsystemCombo.currentText
                                            assignFeedbackTimer.restart()
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

    Timer {
        id: assignFeedbackTimer
        interval: 1800
    }

    Connections {
        target: controller.pciModel
        function onCountChanged() {
            root.usedQuickAssignTokens = ""
        }
    }
}
