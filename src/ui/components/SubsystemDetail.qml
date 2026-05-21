import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Bctl
import QtQuick.Layouts

// Detail panel for a selected subsystem.
Item {
    id: root

    property int subsystemIndex: -1

    signal openPciRequested()

    readonly property string subsystemIcon: {
        if (root.subsystemIndex < 0) return ""
        const s = controller.subsystemModel.getSubsystem(root.subsystemIndex)
        return s["icon"] || controller.iconForSubsystem(s["name"] || "")
    }

    function reload() {
        if (subsystemIndex < 0) return
        root.checkItemsList = controller.subsystemModel.getSubsystem(subsystemIndex)["checkItems"] || []
        const s = controller.subsystemModel.getSubsystem(subsystemIndex)
        nameField.text       = (s["name"]       || "").replace(/ ?\\n ?/g, ' ').trim()
        controllerArea.text  = s["controller"]  || ""
        ifaceField.text      = (s["interfaces"] || "").replace(/ ?\\n ?/g, ' ')
        driverField.text     = s["driver"]      || ""
        noteArea.text        = s["testNote"]    || ""
        hintArea.text        = s["hintText"]    || ""
        cautionArea.text     = s["cautionText"] || ""
        warningArea.text     = s["warningText"] || ""

        const opts = controller.testResultOptions()
        const raw = s["testResult"] || "Успешно"
        const normalized = raw === "успешно" ? "Успешно"
                           : raw === "частично" ? "Условно успешно"
                           : raw === "неуспешно" ? "Неуспешно" : raw
        const ri = opts.indexOf(normalized)
        currentResult = (ri >= 0 ? opts[ri] : "Успешно")

        hintEnabled    = !!s["hintActive"]
        cautionEnabled = !!s["cautionActive"]
        warningEnabled = !!s["warningActive"]
    }

    onSubsystemIndexChanged: reload()

    Connections {
        target: controller.subsystemModel
        function onDataChanged() {
            if (root.subsystemIndex >= 0)
                root.checkItemsList = controller.subsystemModel.getSubsystem(root.subsystemIndex)["checkItems"] || []
        }
    }

    property string currentResult: "Успешно"
    property bool hintEnabled: false
    property bool cautionEnabled: false
    property bool warningEnabled: false

    property var checkItemsList: {
        if (root.subsystemIndex < 0) return []
        return controller.subsystemModel.getSubsystem(root.subsystemIndex)["checkItems"] || []
    }

    function scrollToItem(item) {
        if (!item || !detailScroll.contentItem)
            return
        scrollToTimer.target = item
        scrollToTimer.restart()
    }

    Timer {
        id: scrollToTimer
        interval: 80
        property Item target: null
        onTriggered: {
            if (!target || !detailScroll.contentItem)
                return
            const y = target.mapToItem(detailColumn, 0, 0).y
            const flick = detailScroll.contentItem
            const maxY = Math.max(0, flick.contentHeight - flick.height)
            flick.contentY = Math.max(0, Math.min(y - 32, maxY))
        }
    }

    ScrollView {
        id: detailScroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            id: detailColumn
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
                    text: (nameField.text || "Подсистема").replace(/ ?\\n ?/g, ' ').trim()
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

                        Label {
                            text: "Название подсистемы"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }

                        Bctl.TextField {
                            id: nameField
                            Layout.fillWidth: true
                            placeholderText: ""
                            placeholderTextColor: "#94A3B8"
                            font.pixelSize: 14; color: "#111827"
                            leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                            background: Rectangle {
                                color: "#F9FAFB"; radius: 6
                                border.color: nameField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                border.width: nameField.activeFocus ? 1.5 : 1
                            }
                            onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "name", text)
                        }
                    }
                }

                // Controller (не для подсистемы ввода — контроллер обычно «-»)
                Rectangle {
                    visible: root.subsystemIcon !== "keyboard"
                    Layout.fillWidth: true
                    implicitHeight: ctrlCardContent.implicitHeight + 32
                    color: "white"; radius: 8
                    border.color: "#E5E7EB"; border.width: 1

                    ColumnLayout {
                        id: ctrlCardContent
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
                        spacing: 8

                        FieldLabelRow {
                            Layout.fillWidth: true
                            labelText: "Контроллер"
                            helpExamples: controller.fieldExamples("subsystem", "controller", root.subsystemIcon)
                        }

                        Bctl.TextArea {
                            id: controllerArea
                            Layout.fillWidth: true
                            implicitHeight: 64
                            placeholderText: controller.fieldPlaceholder("subsystem", "controller", root.subsystemIcon)
                            placeholderTextColor: "#94A3B8"
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
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

                        Label {
                            text: "Интерфейс(ы)"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8

                            Bctl.TextField {
                                id: ifaceField
                                Layout.fillWidth: true
                                placeholderText: controller.fieldPlaceholder("subsystem", "interfaces", root.subsystemIcon)
                                placeholderTextColor: "#94A3B8"
                                font.pixelSize: 14; color: "#111827"
                                leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                                background: Rectangle {
                                    color: "#F9FAFB"; radius: 6
                                    border.color: ifaceField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                    border.width: ifaceField.activeFocus ? 1.5 : 1
                                }
                                onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "interfaces", text)
                            }

                            InterfacePickerPopup {
                                implicitWidth: 110; implicitHeight: 34
                                presets: controller.interfacePresetsForSubsystem(root.subsystemIndex)
                                onApply: function(v) {
                                    // v contains " \n " separators for the report engine
                                    // show in field without \n for readability
                                    var display = v.replace(/ ?\\n ?/g, ', ')
                                    ifaceField.text = ifaceField.text !== ""
                                        ? ifaceField.text + ", " + display
                                        : display
                                    // save with \n separators for report engine
                                    var raw = ifaceField.text.replace(/,\s*/g, ' \\n ')
                                    controller.subsystemModel.setField(root.subsystemIndex, "interfaces", raw)
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

                        Label {
                            text: "Драйвер"
                            font.pixelSize: 13
                            color: "#6B7280"
                        }

                        RowLayout {
                            Layout.fillWidth: true; spacing: 8

                            Bctl.TextField {
                                id: driverField
                                Layout.fillWidth: true
                                placeholderText: controller.fieldPlaceholder("subsystem", "driver", root.subsystemIcon)
                                placeholderTextColor: "#94A3B8"
                                font.pixelSize: 14; color: "#111827"
                                leftPadding: 10; rightPadding: 10; topPadding: 8; bottomPadding: 8
                                background: Rectangle {
                                    color: "#F9FAFB"; radius: 6
                                    border.color: driverField.activeFocus ? "#3B82F6" : "#E5E7EB"
                                    border.width: driverField.activeFocus ? 1.5 : 1
                                }
                                onEditingFinished: controller.subsystemModel.setField(root.subsystemIndex, "driver", text)
                            }

                            PresetPickerPopup {
                                implicitWidth: 110; implicitHeight: 34
                                presets: controller.driverPresetsForSubsystem(root.subsystemIndex)
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
                            model: root.checkItemsList

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

                                    Bctl.TextField {
                                        Layout.fillWidth: true
                                        text: modelData
                                        font.pixelSize: 14; color: "#111827"
                                        placeholderTextColor: "#94A3B8"
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

                                Bctl.TextField {
                                    id: checkField
                                    Layout.fillWidth: true
                                    placeholderText: "Добавить пункт..."
                                    placeholderTextColor: "#94A3B8"
                                    font.pixelSize: 14; background: null; leftPadding: 0
                                    onAccepted: root.addCheck()
                                }

                                PresetPickerPopup {
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

                        FieldLabelRow {
                            Layout.fillWidth: true
                            labelText: "Примечание"
                            helpExamples: controller.fieldExamples("subsystem", "testNote", root.subsystemIcon)
                        }

                        Bctl.TextArea {
                            id: noteArea
                            Layout.fillWidth: true; implicitHeight: 72
                            placeholderText: ""
                            placeholderTextColor: "#94A3B8"
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
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

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Label {
                                text: "Типы замечаний"
                                font.pixelSize: 13
                                color: "#6B7280"
                            }

                            FieldHelpIcon {
                                sections: [
                                    {
                                        title: "Замечание",
                                        examples: controller.fieldExamples("subsystem", "hintText", "")
                                    },
                                    {
                                        title: "Предупреждение",
                                        examples: controller.fieldExamples("subsystem", "cautionText", "")
                                    },
                                    {
                                        title: "Ошибка",
                                        examples: controller.fieldExamples("subsystem", "warningText", "")
                                    }
                                ]
                            }

                            Item { Layout.fillWidth: true }
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: 24

                            Repeater {
                                model: [
                                    { key: "hint",    label: "Замечание",      icon: "qrc:/resources/icons/remark-hint.svg"    },
                                    { key: "caution", label: "Предупреждение", icon: "qrc:/resources/icons/remark-caution.svg" },
                                    { key: "warning", label: "Ошибка",         icon: "qrc:/resources/icons/remark-error.svg"   }
                                ]
                                delegate: Row {
                                    spacing: 8
                                    height: 28

                                    readonly property bool isOn: {
                                        if (modelData.key === "hint")    return hintEnabled
                                        if (modelData.key === "caution") return cautionEnabled
                                        return warningEnabled
                                    }

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        source: modelData.icon
                                        opacity: parent.isOn ? 1.0 : 0.45
                                    }

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modelData.label
                                        font.pixelSize: 12
                                        color: parent.isOn ? "#374151" : "#6B7280"
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 36
                                        height: 20
                                        radius: 10
                                        color: {
                                            if (modelData.key === "hint")    return parent.isOn ? "#3B82F6" : "#D1D5DB"
                                            if (modelData.key === "caution") return parent.isOn ? "#D97706" : "#D1D5DB"
                                            return parent.isOn ? "#DC2626" : "#D1D5DB"
                                        }

                                        Rectangle {
                                            width: 16
                                            height: 16
                                            radius: 8
                                            color: "white"
                                            anchors.verticalCenter: parent.verticalCenter
                                            x: parent.parent.isOn ? 18 : 2
                                            Behavior on x { NumberAnimation { duration: 100 } }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData.key === "hint") {
                                                    hintEnabled = !hintEnabled
                                                    controller.subsystemModel.setField(root.subsystemIndex, "hintActive", hintEnabled)
                                                    if (hintEnabled)
                                                        root.scrollToItem(hintArea)
                                                } else if (modelData.key === "caution") {
                                                    cautionEnabled = !cautionEnabled
                                                    controller.subsystemModel.setField(root.subsystemIndex, "cautionActive", cautionEnabled)
                                                    if (cautionEnabled)
                                                        root.scrollToItem(cautionArea)
                                                } else {
                                                    warningEnabled = !warningEnabled
                                                    controller.subsystemModel.setField(root.subsystemIndex, "warningActive", warningEnabled)
                                                    if (warningEnabled)
                                                        root.scrollToItem(warningArea)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Hint text area
                        Bctl.TextArea {
                            id: hintArea
                            visible: hintEnabled
                            Layout.fillWidth: true; implicitHeight: 64
                            placeholderText: controller.fieldPlaceholder("subsystem", "hintText", "")
                            placeholderTextColor: "#94A3B8"
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
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
                        Bctl.TextArea {
                            id: cautionArea
                            visible: cautionEnabled
                            Layout.fillWidth: true; implicitHeight: 64
                            placeholderText: controller.fieldPlaceholder("subsystem", "cautionText", "")
                            placeholderTextColor: "#94A3B8"
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
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
                        Bctl.TextArea {
                            id: warningArea
                            visible: warningEnabled
                            Layout.fillWidth: true; implicitHeight: 64
                            placeholderText: controller.fieldPlaceholder("subsystem", "warningText", "")
                            placeholderTextColor: "#94A3B8"
                            wrapMode: TextEdit.WrapAtWordBoundaryOrAnywhere
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
