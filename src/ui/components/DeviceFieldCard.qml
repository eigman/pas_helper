import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Basic as Bctl
import QtQuick.Layouts

// Single field card: label above, text input below, rounded border
Rectangle {
    id: root

    property string fieldLabel: ""
    property string fieldPlaceholder: ""
    property string fieldValue: ""

    signal fieldChanged(string value)

    implicitHeight: cardContent.implicitHeight + 32
    color: "white"
    radius: 8
    border.color: "#E5E7EB"
    border.width: 1

    ColumnLayout {
        id: cardContent
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 8

        Label {
            text: root.fieldLabel
            font.pixelSize: 13
            color: "#6B7280"
        }

        Bctl.TextField {
            id: field
            Layout.fillWidth: true
            text: root.fieldValue
            placeholderText: root.fieldPlaceholder
            font.pixelSize: 14
            color: "#111827"
            placeholderTextColor: "#94A3B8"
            leftPadding: 10
            rightPadding: 10
            topPadding: 8
            bottomPadding: 8
            background: Rectangle {
                color: "#F9FAFB"
                radius: 6
                border.color: field.activeFocus ? "#3B82F6" : "#E5E7EB"
                border.width: field.activeFocus ? 1.5 : 1
            }
            onEditingFinished: root.fieldChanged(text)

            Binding {
                target: field
                property: "text"
                value: root.fieldValue
                when: !field.activeFocus
            }
        }
    }
}
