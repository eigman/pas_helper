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

    Material.theme: Material.Dark
    Material.accent: Material.Teal
    Material.primary: Material.BlueGrey

    // ── Menu bar ─────────────────────────────────────────────────────────────
    menuBar: MenuBar {
        Menu {
            title: "&Файл"
            Action {
                text: "Новый отчёт"
                shortcut: StandardKey.New
                onTriggered: controller.newReport()
            }
            Action {
                text: "Открыть..."
                shortcut: StandardKey.Open
                onTriggered: openDialog.open()
            }
            MenuSeparator {}
            Action {
                text: "Сохранить"
                shortcut: StandardKey.Save
                enabled: controller.isModified
                onTriggered: {
                    if (controller.currentFilePath === "")
                        saveAsDialog.open()
                    else
                        controller.saveFile()
                }
            }
            Action {
                text: "Сохранить как..."
                shortcut: StandardKey.SaveAs
                onTriggered: saveAsDialog.open()
            }
            MenuSeparator {}
            Action {
                text: "Экспортировать TXT..."
                onTriggered: exportDialog.open()
            }
            MenuSeparator {}
            Action {
                text: "Выход"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        }
        Menu {
            title: "&Вид"
            Action {
                text: pciDrawer.visible ? "Скрыть PCI анализатор" : "Открыть PCI анализатор"
                onTriggered: pciDrawer.visible ? pciDrawer.close() : pciDrawer.open()
            }
        }
    }

    // ── Status bar ────────────────────────────────────────────────────────────
    footer: ToolBar {
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Label {
                text: controller.currentFilePath !== ""
                      ? controller.currentFilePath
                      : "Файл не открыт"
                elide: Text.ElideMiddle
                Layout.fillWidth: true
                font.pixelSize: 12
                opacity: 0.7
            }

            Label {
                text: controller.pciStatusMessage
                font.pixelSize: 11
                opacity: 0.6
                color: controller.pciIdsLoaded ? Material.color(Material.Green) : Material.color(Material.Orange)
            }

            Label {
                visible: controller.isModified
                text: "● Не сохранено"
                font.pixelSize: 12
                color: Material.color(Material.Orange)
            }
        }
    }

    // ── Main content: Work / Report tabs ─────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        TabBar {
            id: mainTabBar
            Layout.fillWidth: true

            TabButton { text: "Работа" }
            TabButton { text: "Отчёт" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: mainTabBar.currentIndex

            WorkTab {}
            ReportTab {
                onOpenPciRequested: pciDrawer.open()
                onSaveAsRequested:  saveAsDialog.open()
            }
        }
    }

    // ── PCI Analyzer drawer (right side) ─────────────────────────────────────
    Drawer {
        id: pciDrawer
        width: Math.min(500, root.width * 0.4)
        height: root.height - (root.menuBar ? root.menuBar.height : 0)
        edge: Qt.RightEdge
        modal: false
        interactive: true

        PciPanel {
            anchors.fill: parent
            onAssignToSubsystem: function(pciIndex, subsystemIndex) {
                controller.assignPciToSubsystem(pciIndex, subsystemIndex)
            }
        }
    }

    // ── File dialogs ──────────────────────────────────────────────────────────
    FileDialog {
        id: openDialog
        title: "Открыть отчёт"
        nameFilters: ["Отчёт (*.txt)", "Все файлы (*)"]
        onAccepted: controller.openFile(selectedFile.toString().replace("file://", ""))
    }

    FileDialog {
        id: saveAsDialog
        title: "Сохранить отчёт как"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Отчёт (*.txt)"]
        defaultSuffix: "txt"
        onAccepted: controller.saveFileAs(selectedFile.toString().replace("file://", ""))
    }

    FileDialog {
        id: exportDialog
        title: "Экспортировать TXT"
        fileMode: FileDialog.SaveFile
        nameFilters: ["Текстовый файл (*.txt)"]
        defaultSuffix: "txt"
        onAccepted: controller.exportTxt(selectedFile.toString().replace("file://", ""))
    }

    // ── Error toast ───────────────────────────────────────────────────────────
    Connections {
        target: controller
        function onErrorOccurred(message) {
            errorToast.text = message
            errorToast.open()
        }
    }

    Popup {
        id: errorToast
        property alias text: toastLabel.text
        anchors.centerIn: parent
        modal: false
        padding: 16

        background: Rectangle {
            color: Material.color(Material.Red, Material.Shade700)
            radius: 4
        }

        Label {
            id: toastLabel
            color: "white"
        }

        Timer {
            running: errorToast.visible
            interval: 4000
            onTriggered: errorToast.close()
        }
    }
}
