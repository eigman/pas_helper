import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Detail panel for a selected subsystem.
Item {
    id: root

    property int subsystemIndex: -1

    signal openPciRequested()

    function reload() {
        if (subsystemIndex < 0) return
        const s = controller.subsystemModel.getSubsystem(subsystemIndex)
        nameField.text       = s["name"]        || ""
        controllerArea.text  = s["controller"]  || ""
        ifaceField.text      = s["interfaces"]  || ""
        driverField.text     = s["driver"]      || ""
        noteArea.text        = s["testNote"]    || ""
        hintArea.text        = s["hintText"]    || ""
        cautionArea.text     = s["cautionText"] || ""
        warningArea.text     = s["warningText"] || ""

        const opts = controller.testResultOptions()
        const ri = opts.indexOf(s["testResult"] || "успешно")
        currentResult = (ri >= 0 ? opts[ri] : "успешно")

        // Determine active remark types
        hintEnabled    = (s["hintText"]    || "") !== ""
        cautionEnabled = (s["cautionText"] || "") !== ""
        warningEnabled = (s["warningText"] || "") !== ""
    }

    onSubsystemIndexChanged: reload()

    Connections {
        target: controller.subsystemModel
        function onDataChanged() { root.reload() }
    }

    property string currentResult: "успешно"
    property bool hintEnabled: false
    property bool cautionEnabled: false
    property bool warningEnabled: false

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
                    text: nameField.text || "Подсистема"
                    font.pixelSize: 20
                    font.weight: Font.Medium
                    color: "#111827"
                }
            }

            // ── Subsystem heading ─────────────────────────────────────────────
            Label {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.topMargin: 24
                Layout.bottomMargin: 12
                text: "Технические параметры устройства"
                font.pixelSize: 16
                font.weight: Font.Medium
                color: "#374151"
            }

            // ── Basic field cards ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 32
                Layout.rightMargin: 32
                spacing: 12

                // Name
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: nameCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: nameCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 8

                        Label { text: "Название подсистемы"; font.pixelSize: 13; color: "#6B7280" }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: nameField
                                Layout.fillWidth: true
                                placeholderText: "напр. Дисковая \\n подсистема"
                                font.pixelSize: 14; color: "#111827"
                                leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                                background: Rectangle {
                                    color: "#F9FAFB"; radius: 6
                                    border.color: nameField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                    border.width: nameField.activeFocus ? 1.5 : 1
                                }
                                onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "name", text)
                            }

                            Label {
                                text: "(\\n = перенос в таблице)"
                                font.pixelSize: 11; color: "#9CA3AF"
                            }
                        }
                    }
                }

                // Controller
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: ctrlCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: ctrlCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 8

                        Label { text: "Контроллер"; font.pixelSize: 13; color: "#6B7280" }

                        TextArea {
                            id: controllerArea
                            Layout.fillWidth: true
                            implicitHeight: 64
                            placeholderText: "напр. Raptor Lake SATA AHCI Controller \\n[**8086:7a62**]"
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 14; color: "#111827"
                            topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                            background: Rectangle {
                                color: "#F9FAFB"; radius: 6
                                border.color: controllerArea.activeFocus ? "#3B82F6" : "#E5E7EB"
                                border.width: controllerArea.activeFocus ? 1.5 : 1
                            }
                            onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "controller", text)
                        }

                        // PCI link
                        Rectangle {
                            implicitHeight: 32
                            implicitWidth: pciLinkRow.implicitWidth + 16
                            radius: 6
                            color: pciLinkHover.containsMouse ? "#EFF6FF" : "transparent"
                            border.color: pciLinkHover.containsMouse ? "#BFDBFE" : "transparent"
                            border.width: 1

                            RowLayout {
                                id: pciLinkRow
                                anchors.centerIn: parent
                                spacing: 4

                                Image {
                                    source: "qrc:/resources/icons/pci.svg"
                                    width: 14; height: 14
                                    opacity: 0.6
                                }
                                Label {
                                    text: "Открыть PCI анализатор"
                                    font.pixelSize: 12
                                    color: pciLinkHover.containsMouse ? "#1D4ED8" : "#6B7280"
                                }
                            }

                            HoverHandler { id: pciLinkHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openPciRequested()
                            }
                        }
                    }
                }

                // Interfaces
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: ifaceCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: ifaceCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 8

                        Label { text: "Интерфейс(ы)"; font.pixelSize: 13; color: "#6B7280" }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8

                            TextField {
                                id: ifaceField
                                Layout.fillWidth: true
                                placeholderText: "напр. Serial ATA  или  1x HDMI \\n 1x VGA"
                                font.pixelSize: 14; color: "#111827"
                                leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                                background: Rectangle {
                                    color: "#F9FAFB"; radius: 6
                                    border.color: ifaceField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                    border.width: ifaceField.activeFocus ? 1.5 : 1
                                }
                                onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "interfaces", text)
                            }

                            PresetsPopup {
                                implicitWidth: 110; implicitHeight: 34
                                presets: controller.interfacePresets()
                                onSelected: function(v) {
                                    ifaceField.text = ifaceField.text !== ""
                                        ? ifaceField.text + " \\n " + v
                                        : v
                                    ifaceField.editingFinished()
                                }
                            }
                        }
                    }
                }

                // Driver
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: driverCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: driverCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 8

                        Label { text: "Драйвер"; font.pixelSize: 13; color: "#6B7280" }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8

                            TextField {
                                id: driverField
                                Layout.fillWidth: true
                                placeholderText: "напр. devb-ahci"
                                font.pixelSize: 14; color: "#111827"
                                leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                                background: Rectangle {
                                    color: "#F9FAFB"; radius: 6
                                    border.color: driverField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                    border.width: driverField.activeFocus ? 1.5 : 1
                                }
                                onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "driver", text)
                            }

                            PresetsPopup {
                                implicitWidth: 110; implicitHeight: 34
                                presets: controller.driverPresets()
                                onSelected: function(v) {
                                    driverField.text = v
                                    driverField.editingFinished()
                                }
                            }
                        }
                    }
                }

                // ── Check items card ──────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: checksCard.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: checksCard
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 0

                        Label {
                            text: "Перечень проверок"
                            font.pixelSize: 13; color: "#6B7280"
                            Layout.bottomMargin: 12
                        }

                        Repeater {
                            id: checksRepeater
                            model: {
                                if (root.subsystemIndex < 0) return []
                                return controller.subsystemModel.getSubsystem(root.subsystemIndex)["checkItems"] || []
                            }

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
                                        onEditingFinished: {
                                            const items = checksRepeater.model.slice()
                                            items[index] = text
                                            controller.subsystemModel.setCheckItems(root.subsystemIndex, items)
                                        }
                                    }

                                    Rectangle {
                                        width: 24; height: 24; radius: 4
                                        color: chkRemHover.containsMouse ? "#FEE2E2" : "transparent"
                                        Label {
                                            anchors.centerIn: parent; text: "×"; font.pixelSize: 16
                                            color: chkRemHover.containsMouse ? "#DC2626" : "#9CA3AF"
                                        }
                                        HoverHandler { id: chkRemHover }
                                        MouseArea {
                                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: controller.subsystemModel.removeCheckItem(root.subsystemIndex, index)
                                        }
                                    }
                                }
                            }
                        }

                        // Add check item
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            color: addChkHover.containsMouse ? "#F9FAFB" : "white"
                            radius: 6; border.color: "#D1D5DB"; border.width: 1
                            Layout.topMargin: checksRepeater.count > 0 ? 8 : 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8

                                Label { text: "+"; font.pixelSize: 16; color: "#6B7280" }

                                TextField {
                                    id: checkField
                                    Layout.fillWidth: true
                                    placeholderText: "Добавить пункт..."
                                    font.pixelSize: 14; background: null; leftPadding: 0
                                    onAccepted: root.addCheck()
                                }

                                PresetsPopup {
                                    implicitWidth: 110; implicitHeight: 34
                                    presets: {
                                        if (root.subsystemIndex < 0) return []
                                        const name = controller.subsystemModel.getSubsystem(root.subsystemIndex)["name"] || ""
                                        return controller.checksPresets(name)
                                    }
                                    onSelected: function(v) {
                                        controller.subsystemModel.addCheckItem(root.subsystemIndex, v)
                                    }
                                }
                            }

                            HoverHandler { id: addChkHover }
                        }
                    }
                }

                // ── Result toggle card ────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: resCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: resCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 12

                        Label { text: "Результат"; font.pixelSize: 13; color: "#6B7280" }

                        ResultToggle {
                            Layout.fillWidth: true
                            currentValue: root.currentResult
                            onValueChanged: function(v) {
                                root.currentResult = v
                                controller.subsystemModel.setField(root.subsystemIndex, "testResult", v)
                            }
                        }
                    }
                }

                // ── Note card ─────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: noteCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: noteCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 8

                        Label { text: "Примечание"; font.pixelSize: 13; color: "#6B7280" }

                        TextArea {
                            id: noteArea
                            Layout.fillWidth: true; implicitHeight: 72
                            placeholderText: "Примечание для итоговой таблицы"
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 14; color: "#111827"
                            topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                            background: Rectangle {
                                color: "#F9FAFB"; radius: 6
                                border.color: noteArea.activeFocus ? "#3B82F6" : "#E5E7EB"
                                border.width: noteArea.activeFocus ? 1.5 : 1
                            }
                            onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "testNote", text)
                        }
                    }
                }

                // ── Remark types card ─────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: remarkCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: remarkCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 12

                        Label { text: "Типы замечаний"; font.pixelSize: 13; color: "#6B7280" }

                        // Toggle row for Hint / Caution / Warning
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            Repeater {
                                model: [
                                    { key: "hint",    label: "Hint",    icon: "ℹ",  color: "#3B82F6" },
                                    { key: "caution", label: "Caution", icon: "⚠",  color: "#D97706" },
                                    { key: "warning", label: "Warning", icon: "ℹ",  color: "#DC2626" }
                                ]
                                delegate: RowLayout {
                                    spacing: 6
                                    Layout.fillWidth: true

                                    Label {
                                        text: modelData.icon
                                        font.pixelSize: 13
                                        color: {
                                            if (modelData.key === "hint")    return hintEnabled    ? modelData.color : "#9CA3AF"
                                            if (modelData.key === "caution") return cautionEnabled ? modelData.color : "#9CA3AF"
                                            return warningEnabled ? modelData.color : "#9CA3AF"
                                        }
                                    }

                                    Rectangle {
                                        width: 8; height: 8; radius: 4
                                        color: {
                                            const enabled = modelData.key === "hint" ? hintEnabled
                                                          : modelData.key === "caution" ? cautionEnabled
                                                          : warningEnabled
                                            return enabled ? modelData.color : "#D1D5DB"
                                        }
                                    }

                                    Label {
                                        text: modelData.label
                                        font.pixelSize: 13
                                        color: {
                                            const enabled = modelData.key === "hint" ? hintEnabled
                                                          : modelData.key === "caution" ? cautionEnabled
                                                          : warningEnabled
                                            return enabled ? modelData.color : "#6B7280"
                                        }
                                        Layout.fillWidth: true
                                    }

                                    // Toggle switch
                                    Rectangle {
                                        width: 36; height: 20; radius: 10
                                        color: {
                                            const enabled = modelData.key === "hint" ? hintEnabled
                                                          : modelData.key === "caution" ? cautionEnabled
                                                          : warningEnabled
                                            return enabled ? modelData.color : "#D1D5DB"
                                        }

                                        Rectangle {
                                            width: 16; height: 16; radius: 8
                                            color: "white"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: {
                                                const enabled = modelData.key === "hint" ? hintEnabled
                                                              : modelData.key === "caution" ? cautionEnabled
                                                              : warningEnabled
                                                return enabled ? 18 : 2
                                            }
                                            Behavior on x { NumberAnimation { duration: 100 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.key === "hint") {
                                                    hintEnabled = !hintEnabled
                                                    if (!hintEnabled) {
                                                        hintArea.text = ""
                                                        controller.subsystemModel.setField(root.subsystemIndex, "hintText", "")
                                                    }
                                                } else if (modelData.key === "caution") {
                                                    cautionEnabled = !cautionEnabled
                                                    if (!cautionEnabled) {
                                                        cautionArea.text = ""
                                                        controller.subsystemModel.setField(root.subsystemIndex, "cautionText", "")
                                                    }
                                                } else {
                                                    warningEnabled = !warningEnabled
                                                    if (!warningEnabled) {
                                                        warningArea.text = ""
                                                        controller.subsystemModel.setField(root.subsystemIndex, "warningText", "")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Hint text area
                        TextArea {
                            id: hintArea
                            visible: hintEnabled
                            Layout.fillWidth: true; implicitHeight: 64
                            placeholderText: "Текст замечания @hint..."
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 14; color: "#111827"
                            topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                            background: Rectangle {
                                color: "#EFF6FF"; radius: 6
                                border.color: hintArea.activeFocus ? "#3B82F6" : "#BFDBFE"
                                border.width: 1
                            }
                            onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "hintText", text)
                        }

                        // Caution text area
                        TextArea {
                            id: cautionArea
                            visible: cautionEnabled
                            Layout.fillWidth: true; implicitHeight: 64
                            placeholderText: "Текст предупреждения @caution..."
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 14; color: "#111827"
                            topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                            background: Rectangle {
                                color: "#FFFBEB"; radius: 6
                                border.color: cautionArea.activeFocus ? "#D97706" : "#FDE68A"
                                border.width: 1
                            }
                            onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "cautionText", text)
                        }

                        // Warning text area
                        TextArea {
                            id: warningArea
                            visible: warningEnabled
                            Layout.fillWidth: true; implicitHeight: 64
                            placeholderText: "Текст ошибки @warning..."
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 14; color: "#111827"
                            topPadding: 8; leftPadding: 10; rightPadding: 10; bottomPadding: 8
                            background: Rectangle {
                                color: "#FEF2F2"; radius: 6
                                border.color: warningArea.activeFocus ? "#DC2626" : "#FECACA"
                                border.width: 1
                            }
                            onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "warningText", text)
                        }
                    }
                }

                Item { implicitHeight: 32 }
            }
        }
    }

    function addCheck() {
        if (checkField.text.trim() !== "") {
            controller.subsystemModel.addCheckItem(root.subsystemIndex, checkField.text)
            checkField.text = ""
        }
    }
}
