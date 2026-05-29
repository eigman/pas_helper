import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    focus: true

    readonly property int idx: controller.currentWorkStepIndex
    readonly property int total: controller.workStepCount
    readonly property bool canPrev: idx > 0
    readonly property bool canNext: idx < total - 1

    // Track previous index so we can flush the note before switching.
    property int _prevIdx: 0

    Keys.onLeftPressed:  if (canPrev) controller.prevWorkStep()
    Keys.onRightPressed: if (canNext) controller.nextWorkStep()

    function flushNote() {
        if (total > 0)
            controller.workStepModel.setNote(_prevIdx, noteArea.text)
    }

    function syncFields() {
        flushNote()
        _prevIdx = idx
        noteArea.text         = total > 0 ? controller.workStepModel.noteAt(idx) : ""
        statusToggle.currentValue = total > 0 ? controller.workStepModel.statusAt(idx) : ""
    }

    Component.onCompleted: { _prevIdx = idx; syncFields() }

    Connections {
        target: controller
        function onCurrentWorkStepIndexChanged() { root.syncFields() }
    }
    Connections {
        target: controller.workStepModel
        function onStepDataChanged() {
            if (!noteArea.activeFocus)
                noteArea.text = total > 0 ? controller.workStepModel.noteAt(idx) : ""
            if (!statusToggle.activeFocus)
                statusToggle.currentValue = total > 0 ? controller.workStepModel.statusAt(idx) : ""
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Step list ─────────────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            color: "#F8F9FA"

            Rectangle {
                anchors.right: parent.right
                width: 1; height: parent.height
                color: "#E5E7EB"
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Header — same height as right panel header
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 56
                    color: "white"

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        color: "#E5E7EB"
                    }

                    Label {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Этапы"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        color: "#374151"
                    }
                }

                ListView {
                    id: stepList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: controller.workStepModel
                    spacing: 4
                    topMargin: 8
                    bottomMargin: 8
                    leftMargin: 8
                    rightMargin: 8

                    delegate: WorkStepListItem {
                        width: stepList.width - 16
                        title: model.title
                        status: model.status
                        selected: controller.currentWorkStepIndex === index
                        onClicked: controller.goToWorkStep(index)
                    }
                }
            }
        }

        // ── Detail pane ───────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Header
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 56
                color: "white"

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; height: 1
                    color: "#E5E7EB"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12

                    Label {
                        text: total > 0 ? controller.workStepModel.titleAt(idx) : "Рабочий лист"
                        font.pixelSize: 17
                        font.weight: Font.Medium
                        color: "#111827"
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Label {
                        text: (idx + 1) + " / " + total
                        font.pixelSize: 12
                        color: "#6B7280"
                    }

                    WorkNavButton {
                        icon: "‹"
                        enabled: canPrev
                        onTriggered: controller.prevWorkStep()
                    }
                    WorkNavButton {
                        icon: "›"
                        enabled: canNext
                        onTriggered: controller.nextWorkStep()
                    }
                }
            }

            // Content
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: 16
                spacing: 12

                // Instruction — main area, fills all available space
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 180
                    radius: 8
                    color: "#F8FAFC"
                    border.color: "#E2E8F0"
                    border.width: 1

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 14
                        clip: true
                        contentWidth: availableWidth

                        InstructionView {
                            width: parent.width
                            source: total > 0 ? controller.workStepModel.instructionAt(idx) : ""
                        }
                    }
                }

                // Status toggle
                ResultToggle {
                    id: statusToggle
                    Layout.fillWidth: true
                    onValueChanged: function(v) {
                        if (total > 0)
                            controller.workStepModel.setStatus(idx, v)
                    }
                }

                // Note field
                TextArea {
                    id: noteArea
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88
                    Layout.maximumHeight: 120
                    placeholderText: "Текст заметки"
                    wrapMode: TextArea.Wrap
                    font.pixelSize: 13
                    color: "#374151"
                    placeholderTextColor: "#9CA3AF"
                    topPadding: 8
                    leftPadding: 10
                    rightPadding: 10
                    bottomPadding: 8
                    background: Rectangle {
                        radius: 8
                        color: "#F9FAFB"
                        border.color: noteArea.activeFocus ? "#93C5FD" : "#E5E7EB"
                        border.width: 1
                    }
                    onActiveFocusChanged: {
                        if (!activeFocus && total > 0)
                            controller.workStepModel.setNote(idx, text)
                    }
                }
            }
        }
    }

    Connections {
        target: controller
        function onCurrentWorkStepIndexChanged() {
            stepList.positionViewAtIndex(controller.currentWorkStepIndex, ListView.Contain)
        }
    }
}
