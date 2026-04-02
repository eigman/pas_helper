import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Work tab — personal notepad and checklist, independent from report content.
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

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 32
                    anchors.rightMargin: 32

                    Label {
                        text: "Рабочий лист"
                        font.pixelSize: 20
                        font.weight: Font.Medium
                        color: "#111827"
                        Layout.fillWidth: true
                    }

                    Label {
                        text: doneCount + " / " + controller.workItemModel.count + " выполнено"
                        font.pixelSize: 13
                        color: "#6B7280"

                        property int doneCount: {
                            let n = 0
                            for (let i = 0; i < controller.workItemModel.count; i++) {
                                if (controller.workItemModel.isDone(i)) n++
                            }
                            return n
                        }
                    }
                }
            }

            // ── Content ───────────────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 32
                spacing: 20

                // ── Checklist card ────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: checklistContent.implicitHeight + 32
                    color: "white"
                    radius: 8
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        id: checklistContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 0

                        Label {
                            text: "Чек-лист проверки"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#374151"
                            Layout.bottomMargin: 12
                        }

                        // Check items
                        Repeater {
                            id: checkListRepeater
                            model: controller.workItemModel

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 44
                                color: "white"

                                // Bottom divider
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: 1
                                    color: "#F3F4F6"
                                    visible: index < checkListRepeater.count - 1
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 4
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Custom checkbox
                                    Rectangle {
                                        width: 18
                                        height: 18
                                        radius: 4
                                        border.color: model.done ? "#3B82F6" : "#D1D5DB"
                                        border.width: 1.5
                                        color: model.done ? "#3B82F6" : "white"
                                        Layout.alignment: Qt.AlignVCenter

                                        Label {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.pixelSize: 11
                                            color: "white"
                                            visible: model.done
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: controller.workItemModel.setDone(index, !model.done)
                                        }
                                    }

                                    TextField {
                                        text: model.itemText
                                        Layout.fillWidth: true
                                        placeholderText: "Пункт проверки..."
                                        font.pixelSize: 14
                                        font.strikeout: model.done
                                        color: model.done ? "#9CA3AF" : "#111827"
                                        background: null
                                        leftPadding: 0
                                        onEditingFinished: controller.workItemModel.setText(index, text)
                                    }

                                    // Remove button
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 4
                                        color: removeHover.containsMouse ? "#FEE2E2" : "transparent"

                                        Label {
                                            anchors.centerIn: parent
                                            text: "×"
                                            font.pixelSize: 16
                                            color: removeHover.containsMouse ? "#DC2626" : "#9CA3AF"
                                        }

                                        HoverHandler { id: removeHover }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: controller.workItemModel.removeItem(index)
                                        }
                                    }
                                }
                            }
                        }

                        // Add item row
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            color: "white"
                            visible: checkListRepeater.count > 0

                            Rectangle {
                                anchors.top: parent.top
                                width: parent.width
                                height: 1
                                color: "#F3F4F6"
                            }

                            // placeholder handled below
                        }

                        // Add new item — dashed border row
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 44
                            color: addItemHover.containsMouse ? "#F9FAFB" : "white"
                            radius: 6
                            border.color: "#D1D5DB"
                            border.width: 1

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
                                    id: newItemField
                                    Layout.fillWidth: true
                                    placeholderText: "Добавить пункт..."
                                    font.pixelSize: 14
                                    color: "#111827"
                                    background: null
                                    leftPadding: 0
                                    onAccepted: addItem()
                                }

                                // Presets dropdown
                                PresetsPopup {
                                    buttonLabel: "Из пресетов"
                                    implicitWidth: 120; implicitHeight: 34
                                    presets: controller.osInstallChecksPresets()
                                    onSelected: function(v) { controller.workItemModel.addItem(v) }
                                }
                            }

                            HoverHandler { id: addItemHover }
                        }
                    }
                }

                // ── Notes card ────────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 280
                    color: "white"
                    radius: 8
                    border.color: "#E5E7EB"
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        Label {
                            text: "Заметки"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#374151"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#F3F4F6"
                        }

                        TextArea {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: controller.workNotes
                            placeholderText: "Здесь можно писать заметки по ходу работы, алгоритмы действий, промежуточные результаты...\n\nЭти заметки не попадают в отчёт."
                            wrapMode: TextArea.Wrap
                            font.pixelSize: 13
                            color: "#374151"
                            background: null
                            topPadding: 0
                            leftPadding: 0
                            onTextChanged: controller.workNotes = text
                        }
                    }
                }

                Item { implicitHeight: 16 }
            }
        }
    }

    function addItem() {
        if (newItemField.text.trim() !== "") {
            controller.workItemModel.addItem(newItemField.text)
            newItemField.text = ""
        }
    }
}
