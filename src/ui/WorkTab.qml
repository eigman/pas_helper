import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Work tab — personal notepad and checklist, independent from report content.
Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Label {
                text: "Рабочий лист"
                font.pixelSize: 18
                font.bold: true
                Layout.fillWidth: true
            }
            Label {
                text: doneCount + " / " + controller.workItemModel.count + " выполнено"
                font.pixelSize: 13
                opacity: 0.7

                property int doneCount: {
                    let n = 0
                    for (let i = 0; i < controller.workItemModel.count; i++) {
                        if (controller.workItemModel.data(
                                controller.workItemModel.index(i, 0), 258)) // DoneRole = UserRole+2
                            n++
                    }
                    return n
                }
            }
        }

        // Checklist
        GroupBox {
            title: "Чек-лист проверки"
            Layout.fillWidth: true
            Layout.preferredHeight: 300

            ColumnLayout {
                anchors.fill: parent
                spacing: 4

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: checkList
                        model: controller.workItemModel
                        spacing: 2

                        delegate: RowLayout {
                            width: checkList.width
                            spacing: 8

                            CheckBox {
                                checked: model.done
                                onToggled: controller.workItemModel.setDone(index, checked)
                            }

                            TextField {
                                text: model.itemText
                                Layout.fillWidth: true
                                placeholderText: "Пункт проверки..."
                                font.strikeout: model.done
                                opacity: model.done ? 0.5 : 1.0
                                background: null
                                onEditingFinished: controller.workItemModel.setText(index, text)
                            }

                            ToolButton {
                                icon.name: "list-remove"
                                text: "✕"
                                font.pixelSize: 11
                                opacity: 0.5
                                onClicked: controller.workItemModel.removeItem(index)
                            }
                        }

                        // Empty state
                        Label {
                            visible: checkList.count === 0
                            anchors.centerIn: parent
                            text: "Добавьте пункты проверки"
                            opacity: 0.4
                        }
                    }
                }

                // Add item controls
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: newItemField
                        Layout.fillWidth: true
                        placeholderText: "Новый пункт..."
                        onAccepted: addItem()
                    }

                    Button {
                        text: "Добавить"
                        Material.accent: Material.Teal
                        onClicked: addItem()
                    }

                    ComboBox {
                        id: presetsCombo
                        model: controller.osInstallChecksPresets()
                        displayText: "Из пресетов"
                        implicitWidth: 150
                        onActivated: {
                            controller.workItemModel.addItem(currentText)
                        }
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

        // Notes area
        GroupBox {
            title: "Заметки"
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent

                TextArea {
                    text: controller.workNotes
                    placeholderText: "Здесь можно писать заметки по ходу работы, алгоритмы действий, промежуточные результаты...\n\nЭти заметки не попадают в отчёт."
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 13
                    onTextChanged: controller.workNotes = text
                }
            }
        }
    }
}
