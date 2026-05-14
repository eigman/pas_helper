import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import ReportAssistant 1.0

ApplicationWindow {
    id: root
    visible: true
    width: 1280
    height: 800
    minimumWidth: 800
    minimumHeight: 560
    title: controller.windowTitle + " — Report Assistant"
    flags: Qt.Window | Qt.FramelessWindowHint

    Material.theme: Material.Light
    Material.accent: Material.Blue
    Material.primary: Material.BlueGrey

    // ── State ─────────────────────────────────────────────────────────────────
    property int mainTabIndex: 0
    property int reportPageIndex: 0
    property int selectedSubsystemIndex: -1

    // Drag support for frameless window
    property point dragOrigin

    // ── Root layout: titlebar + body ──────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // ── Custom titlebar ───────────────────────────────────────────────────
        Rectangle {
            id: titleBar
            Layout.fillWidth: true
            implicitHeight: 44
            color: "#1E293B"

            // Drag to move window
            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 120  // leave window controls area
                onPressed: root.dragOrigin = Qt.point(mouseX, mouseY)
                onPositionChanged: {
                    if (pressed) {
                        root.x += mouseX - root.dragOrigin.x
                        root.y += mouseY - root.dragOrigin.y
                    }
                }
                onDoubleClicked: {
                    root.visibility === Window.Maximized
                        ? root.showNormal()
                        : root.showMaximized()
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 0
                spacing: 0

                // App icon + name
                Rectangle {
                    width: 26; height: 26; radius: 6; color: "#3B82F6"
                    Label {
                        anchors.centerIn: parent
                        text: "⚙"; color: "white"; font.pixelSize: 13
                    }
                }

                Label {
                    text: "Системное тестирование"
                    color: "white"; font.pixelSize: 13; font.weight: Font.Medium
                    leftPadding: 10
                }

                // File menu button
                Rectangle {
                    id: fileMenuBtn
                    implicitWidth: fileMenuLabel.implicitWidth + 24
                    implicitHeight: 28; radius: 5
                    color: fileMenuHover.containsMouse || fileMenuPopup.visible ? "#334155" : "transparent"
                    Layout.leftMargin: 8

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10; anchors.rightMargin: 8
                        spacing: 5
                        Label {
                            id: fileMenuLabel
                            text: "Файл"; color: "#CBD5E1"; font.pixelSize: 12
                        }
                        Label {
                            text: "▾"; color: "#64748B"; font.pixelSize: 9
                        }
                    }

                    HoverHandler { id: fileMenuHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (fileMenuPopup.visible)
                                fileMenuPopup.close()
                            else
                                fileMenuPopup.open()
                        }
                    }
                }

                // Separator
                Rectangle {
                    width: 1; implicitHeight: 20
                    color: "#334155"
                    Layout.leftMargin: 8
                }

                // Работа / Отчёт toggle
                RowLayout {
                    spacing: 2
                    Layout.leftMargin: 8

                    Repeater {
                        model: ["Работа", "Отчёт"]
                        delegate: Rectangle {
                            implicitWidth: tabLbl.implicitWidth + 20
                            implicitHeight: 28; radius: 5
                            color: mainTabIndex === index ? "white" : (tabHover.containsMouse ? "#334155" : "transparent")

                            Label {
                                id: tabLbl
                                anchors.centerIn: parent
                                text: modelData; font.pixelSize: 12
                                font.weight: mainTabIndex === index ? Font.Medium : Font.Normal
                                color: mainTabIndex === index ? "#1E293B" : "#94A3B8"
                            }

                            HoverHandler { id: tabHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mainTabIndex = index
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Window controls
                Row {
                    spacing: 0

                    Repeater {
                        model: [
                            { icon: "─", action: "minimize" },
                            { icon: "□", action: "maximize" },
                            { icon: "✕", action: "close"    }
                        ]
                        delegate: Rectangle {
                            width: 40; height: 44
                            color: {
                                if (modelData.action === "close" && wcHover.containsMouse) return "#DC2626"
                                return wcHover.containsMouse ? "#334155" : "transparent"
                            }
                            Label {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: "#CBD5E1"; font.pixelSize: 13
                            }
                            HoverHandler { id: wcHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.action === "minimize") root.showMinimized()
                                    else if (modelData.action === "maximize")
                                        root.visibility === Window.Maximized ? root.showNormal() : root.showMaximized()
                                    else Qt.quit()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Body: sidebar + content ───────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // ── Left sidebar ──────────────────────────────────────────────────
            Rectangle {
                id: sidebar
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: "#F8F9FA"

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    // Sidebar nav content (Report tab only)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        visible: mainTabIndex === 1

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Label {
                                Layout.fillWidth: true
                                Layout.topMargin: 20; Layout.leftMargin: 16; Layout.bottomMargin: 6
                                text: "НАВИГАЦИЯ"
                                font.pixelSize: 10; font.weight: Font.Medium
                                color: "#94A3B8"; font.letterSpacing: 0.8
                            }

                            SidebarNavItem {
                                Layout.fillWidth: true
                                iconSource: "qrc:/resources/icons/settings.svg"
                                label: "Параметры устройства"
                                selected: reportPageIndex === 0
                                onClicked: reportPageIndex = 0
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.topMargin: 16; Layout.leftMargin: 16
                                Layout.rightMargin: 8; Layout.bottomMargin: 4
                                spacing: 0

                                Label {
                                    text: "ПОДСИСТЕМЫ"
                                    font.pixelSize: 10; font.weight: Font.Medium
                                    color: "#94A3B8"; font.letterSpacing: 0.8
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: 24; height: 24; radius: 4
                                    color: addBtnHover.containsMouse ? "#E5E7EB" : "transparent"

                                    Label {
                                        anchors.centerIn: parent
                                        text: "+"; font.pixelSize: 16; color: "#64748B"
                                    }

                                    HoverHandler { id: addBtnHover }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: addSubsystemDialog.open()
                                    }
                                }
                            }

                            ListView {
                                id: subsystemNavList
                                Layout.fillWidth: true
                                Layout.preferredHeight: contentHeight
                                model: controller.subsystemModel
                                interactive: false; clip: true

                                property var appController: controller

                                delegate: SidebarSubsystemItem {
                                    width: subsystemNavList.width
                                    subsystemName: model.name.replace(/ ?\\n ?/g, ' ').trim()
                                    iconKey: model.icon || "settings"
                                    selected: reportPageIndex === (index + 1)
                                    onClicked: {
                                        selectedSubsystemIndex = index
                                        reportPageIndex = index + 1
                                    }
                                    onRemoveClicked: {
                                        var i = index
                                        subsystemNavList.appController.removeSubsystem(i)
                                        if (selectedSubsystemIndex >= subsystemNavList.appController.subsystemModel.count)
                                            selectedSubsystemIndex = subsystemNavList.appController.subsystemModel.count - 1
                                        if (reportPageIndex > subsystemNavList.appController.subsystemModel.count)
                                            reportPageIndex = 0
                                    }
                                }
                            }

                            SidebarNavItem {
                                Layout.fillWidth: true; Layout.topMargin: 4
                                iconSource: "qrc:/resources/icons/recommendations.svg"
                                label: "Рекомендации"
                                selected: reportPageIndex === controller.subsystemModel.count + 1
                                onClicked: reportPageIndex = controller.subsystemModel.count + 1
                            }

                            Item { Layout.fillHeight: true }

                            Rectangle {
                                Layout.fillWidth: true; Layout.bottomMargin: 4
                                implicitHeight: 1; color: "#E5E7EB"
                                Layout.leftMargin: 16; Layout.rightMargin: 16
                            }

                            SidebarNavItem {
                                Layout.fillWidth: true; Layout.bottomMargin: 8
                                iconSource: "qrc:/resources/icons/pci.svg"
                                label: "PCI Анализатор"
                                selected: false
                                onClicked: pciDrawer.visible ? pciDrawer.close() : pciDrawer.open()
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        visible: mainTabIndex === 0
                    }
                }

                // Right edge — must paint above list row backgrounds or the divider disappears.
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: "#E5E7EB"
                    z: 2
                }
            }

            // ── Main content area ─────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true
                spacing: 0

                // Status bar
                Rectangle {
                    Layout.fillWidth: true; implicitHeight: 32
                    color: "white"

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1; color: "#E5E7EB"
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20; anchors.rightMargin: 16; spacing: 12

                        Label {
                            text: controller.currentFilePath !== ""
                                  ? controller.currentFilePath : "Файл не открыт"
                            elide: Text.ElideMiddle; Layout.fillWidth: true
                            font.pixelSize: 11; color: "#64748B"
                        }

                        Label {
                            text: controller.pciStatusMessage
                            font.pixelSize: 11
                            color: controller.pciIdsLoaded ? "#16A34A" : "#D97706"
                        }

                        Rectangle {
                            visible: controller.isModified
                            implicitWidth: modLbl.implicitWidth + 16
                            implicitHeight: 18; radius: 9; color: "#FEF3C7"

                            Label {
                                id: modLbl; anchors.centerIn: parent
                                text: "Не сохранено"; font.pixelSize: 10; color: "#D97706"
                            }
                        }
                    }
                }

                StackLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true
                    currentIndex: mainTabIndex

                    WorkTab {}

                    ReportTab {
                        pageIndex: reportPageIndex
                        subsystemIndex: selectedSubsystemIndex
                        onOpenPciRequested: pciDrawer.open()
                        onSaveAsRequested:  saveAsDialog.open()
                    }
                }
            }
        }
    }

    // Frameless window: OS resize frame is absent — thin hit-targets on edges and corner.
    Item {
        id: resizeEdges
        anchors.fill: parent
        z: 100
        visible: root.visibility !== Window.FullScreen

        readonly property bool allowResize: root.visibility === Window.Windowed

        MouseArea {
            anchors.right: parent.right
            width: 10
            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.bottom: parent.bottom
            enabled: resizeEdges.allowResize
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            property real _startWidth: 0
            property real _startGlobalX: 0
            onPressed: function(mouse) {
                _startWidth = root.width
                _startGlobalX = mouse.globalX
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                root.width = Math.max(root.minimumWidth, _startWidth + (mouse.globalX - _startGlobalX))
            }
        }
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 10
            enabled: resizeEdges.allowResize
            hoverEnabled: true
            cursorShape: Qt.SizeVerCursor
            property real _startHeight: 0
            property real _startGlobalY: 0
            onPressed: function(mouse) {
                _startHeight = root.height
                _startGlobalY = mouse.globalY
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                root.height = Math.max(root.minimumHeight, _startHeight + (mouse.globalY - _startGlobalY))
            }
        }
        MouseArea {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 14
            height: 14
            enabled: resizeEdges.allowResize
            hoverEnabled: true
            cursorShape: Qt.SizeFDiagCursor
            property real _startW: 0
            property real _startH: 0
            property real _startGX: 0
            property real _startGY: 0
            onPressed: function(mouse) {
                _startW = root.width
                _startH = root.height
                _startGX = mouse.globalX
                _startGY = mouse.globalY
            }
            onPositionChanged: function(mouse) {
                if (!pressed) return
                root.width = Math.max(root.minimumWidth, _startW + (mouse.globalX - _startGX))
                root.height = Math.max(root.minimumHeight, _startH + (mouse.globalY - _startGY))
            }
        }
    }

    // ── File menu popup ───────────────────────────────────────────────────────
    Popup {
        id: fileMenuPopup
        parent: Overlay.overlay
        width: 220
        padding: 6
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        onAboutToShow: {
            var globalPos = fileMenuBtn.mapToItem(null, 0, fileMenuBtn.height + 4)
            var overlayPos = Overlay.overlay.mapFromItem(null, globalPos.x, globalPos.y)
            x = overlayPos.x
            y = overlayPos.y
        }

        background: Rectangle {
            color: "#1E293B"
            radius: 8
            border.color: "#334155"; border.width: 1
            layer.enabled: true
            layer.effect: null
        }

        // Helper component for menu items
        component FileMenuItem: Rectangle {
            property string label: ""
            property bool separator: false
            property bool danger: false
            property bool disabled: false

            signal triggered()

            Layout.fillWidth: true
            implicitHeight: separator ? 9 : 36
            color: "transparent"
            radius: 6

            // Separator line
            Rectangle {
                visible: parent.separator
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left; anchors.right: parent.right
                anchors.leftMargin: 4; anchors.rightMargin: 4
                height: 1; color: "#334155"
            }

            Rectangle {
                visible: !parent.separator
                anchors.fill: parent
                radius: 6
                color: !parent.disabled && itemMouse.containsMouse
                       ? (parent.danger ? "#7F1D1D" : "#334155")
                       : "transparent"

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left; anchors.leftMargin: 12
                    text: label
                    font.pixelSize: 13
                    color: parent.parent.disabled
                           ? "#4B5563"
                           : (parent.parent.danger ? "#FCA5A5" : "#E2E8F0")
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: parent.parent.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !parent.parent.disabled
                    onClicked: {
                        fileMenuPopup.close()
                        parent.parent.parent.triggered()
                    }
                }
            }
        }

        contentItem: ColumnLayout {
            spacing: 0
            width: fileMenuPopup.width - 12

            FileMenuItem {
                label: "Новый отчёт"
                onTriggered: controller.newReport()
            }
            FileMenuItem {
                label: "Открыть..."
                onTriggered: openDialog.open()
            }
            FileMenuItem { separator: true }
            FileMenuItem {
                label: "Сохранить"
                disabled: !controller.isModified
                onTriggered: controller.currentFilePath === "" ? saveAsDialog.open() : controller.saveFile()
            }
            FileMenuItem {
                label: "Сохранить как..."
                onTriggered: saveAsDialog.open()
            }
            FileMenuItem { separator: true }
            FileMenuItem {
                label: "Экспортировать TXT..."
                onTriggered: exportDialog.open()
            }
            FileMenuItem { separator: true }
            FileMenuItem {
                label: "Выход"
                danger: true
                onTriggered: Qt.quit()
            }
        }
    }

    // ── PCI Analyzer drawer ───────────────────────────────────────────────────
    Drawer {
        id: pciDrawer
        width: Math.min(500, root.width * 0.4)
        height: root.height - titleBar.height
        y: titleBar.height
        edge: Qt.RightEdge
        modal: false; interactive: true
        background: Rectangle { color: "white" }

        PciPanel {
            anchors.fill: parent
            onAssignToSubsystem: function(pciIndex, subsystemIndex) {
                controller.assignPciToSubsystem(pciIndex, subsystemIndex)
            }
        }
    }

    // ── Add Subsystem dialog ──────────────────────────────────────────────────
    Popup {
        id: addSubsystemDialog
        modal: true
        anchors.centerIn: parent
        width: 420
        padding: 0
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            color: "white"; radius: 10
            border.color: "#E5E7EB"; border.width: 1
        }

        contentItem: Column {
            spacing: 0
            width: addSubsystemDialog.width

            // Header
            Item {
                width: parent.width; height: 56
                Label {
                    anchors.left: parent.left; anchors.leftMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Добавить подсистему"
                    font.pixelSize: 15; font.weight: Font.Medium; color: "#111827"
                }
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1; color: "#E5E7EB"
                }
            }

            // List
            Repeater {
                model: addSubsystemDialog.visible ? controller.subsystemNamePresets() : []
                delegate: Rectangle {
                    width: parent.width; height: 48
                    color: itemMouse.containsMouse ? "#F3F4F6" : "white"

                    property bool alreadyAdded: {
                        for (let i = 0; i < controller.subsystemModel.count; i++) {
                            const idx = controller.subsystemModel.index(i, 0)
                            const name = controller.subsystemModel.data(idx, Qt.UserRole + 1)
                            const plain = name.replace(/ ?\\n ?/g, ' ').trim()
                            const presetPlain = modelData.replace(/ ?\\n ?/g, ' ').trim()
                            if (plain.toLowerCase() === presetPlain.toLowerCase()) return true
                        }
                        return false
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.right: parent.right
                        anchors.leftMargin: 16; anchors.rightMargin: 16
                        spacing: 12

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/resources/icons/" + controller.iconForSubsystem(modelData) + ".svg"
                            width: 18; height: 18
                            opacity: alreadyAdded ? 0.3 : 0.6
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.replace(/ ?\\n ?/g, ' ')
                            font.pixelSize: 14
                            color: alreadyAdded ? "#9CA3AF" : "#111827"
                        }

                        Item { width: 1; height: 1 }  // spacer

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: alreadyAdded; text: "✓"
                            font.pixelSize: 13; color: "#9CA3AF"
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: alreadyAdded ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !alreadyAdded
                        onClicked: {
                            controller.addSubsystem(modelData)
                            selectedSubsystemIndex = controller.subsystemModel.count - 1
                            reportPageIndex = controller.subsystemModel.count
                        }
                    }
                }
            }

            // Footer
            Item {
                width: parent.width; height: 52
                Rectangle {
                    anchors.top: parent.top
                    width: parent.width; height: 1; color: "#E5E7EB"
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: closePresetsBtn.implicitWidth + 32; height: 36; radius: 6
                    color: closeBtnHover.containsMouse ? "#F3F4F6" : "white"
                    border.color: "#E5E7EB"; border.width: 1

                    Label {
                        id: closePresetsBtn
                        anchors.centerIn: parent
                        text: "Закрыть"; font.pixelSize: 14; color: "#374151"
                    }
                    HoverHandler { id: closeBtnHover }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: addSubsystemDialog.close()
                    }
                }
            }
        }
    }

    // ── File dialogs ──────────────────────────────────────────────────────────
    FileDialog {
        id: openDialog; title: "Открыть отчёт"
        nameFilters: ["Отчёт (*.txt)", "Все файлы (*)"]
        onAccepted: controller.openFile(selectedFile.toString().replace("file://", ""))
    }
    FileDialog {
        id: saveAsDialog; title: "Сохранить отчёт как"
        fileMode: FileDialog.SaveFile; nameFilters: ["Отчёт (*.txt)"]; defaultSuffix: "txt"
        onAccepted: controller.saveFileAs(selectedFile.toString().replace("file://", ""))
    }
    FileDialog {
        id: exportDialog; title: "Экспортировать TXT"
        fileMode: FileDialog.SaveFile; nameFilters: ["Текстовый файл (*.txt)"]; defaultSuffix: "txt"
        onAccepted: controller.exportTxt(selectedFile.toString().replace("file://", ""))
    }

    // ── Error toast ───────────────────────────────────────────────────────────
    Connections {
        target: controller
        function onErrorOccurred(message) { errorToast.text = message; errorToast.open() }
    }

    Popup {
        id: errorToast; property alias text: toastLbl.text
        anchors.centerIn: parent; modal: false; padding: 16
        background: Rectangle { color: "#DC2626"; radius: 8 }
        Label { id: toastLbl; color: "white"; font.pixelSize: 13 }
        Timer { running: errorToast.visible; interval: 4000; onTriggered: errorToast.close() }
    }
}
