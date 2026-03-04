import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Master-detail layout: left = subsystem list, right = detail panel
Item {
    id: root

    property int selectedIndex: -1

    // Bubbled up from SubsystemDetail → connected in ReportTab → main.qml
    signal openPciRequested()

    SplitView {
        anchors.fill: parent
        orientation: Qt.Horizontal

        // ── Left panel: subsystem list ────────────────────────────────────
        Pane {
            SplitView.preferredWidth: 240
            SplitView.minimumWidth: 180
            SplitView.maximumWidth: 360
            padding: 0
            Material.elevation: 2

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header
                Pane {
                    Layout.fillWidth: true
                    padding: 12
                    Material.elevation: 1

                    RowLayout {
                        anchors.fill: parent
                        Label {
                            text: "Подсистемы"
                            font.bold: true
                            Layout.fillWidth: true
                        }
                        Label {
                            text: controller.subsystemModel.count
                            font.bold: true
                            opacity: 0.6
                        }
                    }
                }

                // Subsystem list
                ListView {
                    id: subsystemList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: controller.subsystemModel
                    currentIndex: root.selectedIndex

                    delegate: ItemDelegate {
                        width: subsystemList.width
                        highlighted: ListView.isCurrentItem

                        contentItem: RowLayout {
                            spacing: 8

                            // Completion indicator
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: model.isComplete
                                       ? Material.color(Material.Green)
                                       : Material.color(Material.Orange)
                            }

                            Label {
                                text: model.name.replace(/\\n/g, ' ')
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        onClicked: root.selectedIndex = index
                    }

                    // Empty state
                    Label {
                        visible: subsystemList.count === 0
                        anchors.centerIn: parent
                        text: "Нет подсистем"
                        opacity: 0.4
                    }
                }

                // Add subsystem controls
                Pane {
                    Layout.fillWidth: true
                    padding: 8

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        ComboBox {
                            id: subsystemCombo
                            Layout.fillWidth: true
                            editable: true
                            model: controller.subsystemNamePresets()
                            displayText: editText || "Выбрать подсистему..."
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "+ Добавить"
                            Material.accent: Material.Teal
                            onClicked: {
                                const name = subsystemCombo.editText.trim() ||
                                             subsystemCombo.currentText
                                if (name !== "") {
                                    controller.addSubsystem(name)
                                    root.selectedIndex = controller.subsystemModel.count - 1
                                    subsystemCombo.editText = ""
                                }
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Удалить"
                            flat: true
                            enabled: root.selectedIndex >= 0
                            Material.accent: Material.Red
                            onClicked: {
                                controller.removeSubsystem(root.selectedIndex)
                                root.selectedIndex = Math.min(
                                    root.selectedIndex,
                                    controller.subsystemModel.count - 1)
                            }
                        }
                    }
                }
            }
        }

        // ── Right panel: subsystem detail ─────────────────────────────────
        Item {
            SplitView.fillWidth: true

            // Placeholder when nothing selected
            Label {
                visible: root.selectedIndex < 0
                anchors.centerIn: parent
                text: "Выберите подсистему слева"
                opacity: 0.4
                font.pixelSize: 16
            }

            SubsystemDetail {
                visible: root.selectedIndex >= 0
                anchors.fill: parent
                subsystemIndex: root.selectedIndex
                onOpenPciRequested: root.openPciRequested()
            }
        }
    }
}
