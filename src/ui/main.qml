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
    minimumWidth: 960
    minimumHeight: 600
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
                    implicitWidth: fileMenuLabel.implicitWidth + 20
                    implicitHeight: 28; radius: 5
                    color: fileMenuHover.containsMouse ? "#334155" : "transparent"
                    Layout.leftMargin: 8

                    Label {
                        id: fileMenuLabel
                        anchors.centerIn: parent
                        text: "Файл"; color: "#CBD5E1"; font.pixelSize: 12
                    }

                    HoverHandler { id: fileMenuHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fileMenu.open()
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

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top; anchors.bottom: parent.bottom
                    width: 1; color: "#E5E7EB"
                }

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

                                delegate: SidebarSubsystemItem {
                                    width: subsystemNavList.width
                                    subsystemName: model.name.replace(/\\n/g, ' ')
                                    iconKey: model.icon || "settings"
                                    selected: reportPageIndex === (index + 1)
                                    onClicked: {
                                        selectedSubsystemIndex = index
                                        reportPageIndex = index + 1
                                    }
                                    onRemoveClicked: {
                                        controller.removeSubsystem(index)
                                        if (selectedSubsystemIndex >= controller.subsystemModel.count)
                                            selectedSubsystemIndex = controller.subsystemModel.count - 1
                                        if (reportPageIndex > controller.subsystemModel.count)
                                            reportPageIndex = 0
                                    }
                                }
                            }

                            SidebarNavItem {
                                Layout.fillWidth: true; Layout.topMargin: 4
                                iconSource: "qrc:/resources/icons/settings.svg"
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

    // ── File menu (popup) ─────────────────────────────────────────────────────
    Menu {
        id: fileMenu

        Action {
            text: "Новый отчёт"; shortcut: StandardKey.New
            onTriggered: controller.newReport()
        }
        Action {
            text: "Открыть..."; shortcut: StandardKey.Open
            onTriggered: openDialog.open()
        }
        MenuSeparator {}
        Action {
            text: "Сохранить"; shortcut: StandardKey.Save
            enabled: controller.isModified
            onTriggered: controller.currentFilePath === "" ? saveAsDialog.open() : controller.saveFile()
        }
        Action {
            text: "Сохранить как..."; shortcut: StandardKey.SaveAs
            onTriggered: saveAsDialog.open()
        }
        MenuSeparator {}
        Action {
            text: "Экспортировать TXT..."
            onTriggered: exportDialog.open()
        }
        MenuSeparator {}
        Action {
            text: "Выход"; shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
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
    Dialog {
        id: addSubsystemDialog
        modal: true; anchors.centerIn: parent; width: 420; padding: 0

        background: Rectangle { color: "white"; radius: 8 }

        header: Rectangle {
            implicitHeight: 52; color: "white"; radius: 8
            Label {
                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20
                text: "Добавить подсистему"
                font.pixelSize: 15; font.weight: Font.Medium; color: "#111827"
            }
        }

        contentItem: ColumnLayout {
            spacing: 0; width: addSubsystemDialog.width - 2

            Repeater {
                model: controller.subsystemNamePresets()
                delegate: Rectangle {
                    Layout.fillWidth: true; implicitHeight: 48
                    color: itemHover.containsMouse ? "#F3F4F6" : "white"

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

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12

                        Image {
                            source: "qrc:/resources/icons/" + controller.iconForSubsystem(modelData) + ".svg"
                            width: 18; height: 18
                            opacity: alreadyAdded ? 0.35 : 0.55
                        }

                        Label {
                            text: modelData.replace(/ ?\\n ?/g, ' ')
                            font.pixelSize: 14
                            color: alreadyAdded ? "#9CA3AF" : "#111827"
                            Layout.fillWidth: true
                        }

                        Label {
                            visible: alreadyAdded; text: "Добавлено"
                            font.pixelSize: 12; color: "#9CA3AF"
                        }
                    }

                    HoverHandler { id: itemHover }
                    MouseArea {
                        anchors.fill: parent
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

            Rectangle {
                Layout.fillWidth: true; implicitHeight: 1; color: "#E5E7EB"
                Layout.topMargin: 4
            }
        }

        footer: Rectangle {
            implicitHeight: 52; color: "white"; radius: 8
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: "Закрыть"; flat: true; font.pixelSize: 14
                onClicked: addSubsystemDialog.close()
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
