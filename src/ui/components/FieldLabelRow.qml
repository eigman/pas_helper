import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root

    property string labelText: ""
    property var helpExamples: []

    spacing: 6

    Label {
        text: root.labelText
        font.pixelSize: 13
        color: "#6B7280"
    }

    FieldHelpIcon {
        visible: root.helpExamples.length > 0
        examples: root.helpExamples
        popupTitle: root.labelText
    }

    Item { Layout.fillWidth: true }
}
