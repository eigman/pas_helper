import QtQuick
import QtQuick.Layouts

// Three-option result toggle: успешно / неуспешно / частично
// Matches the pill-style selector from the design screenshots
RowLayout {
    id: root

    property string currentValue: "успешно"

    signal valueChanged(string value)

    spacing: 8

    Repeater {
        model: [
            { value: "успешно",   label: "Успешно",       activeColor: "#16A34A", activeBg: "#F0FDF4", activeBorder: "#16A34A" },
            { value: "неуспешно", label: "Провалено",     activeColor: "#DC2626", activeBg: "#FEF2F2", activeBorder: "#DC2626" },
            { value: "частично",  label: "Предупреждение", activeColor: "#D97706", activeBg: "#FFFBEB", activeBorder: "#D97706" }
        ]

        delegate: Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 18
            color: root.currentValue === modelData.value ? modelData.activeBg : "white"
            border.color: root.currentValue === modelData.value ? modelData.activeBorder : "#E5E7EB"
            border.width: root.currentValue === modelData.value ? 1.5 : 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.currentValue === modelData.value ? modelData.activeColor : "#D1D5DB"
                }

                Text {
                    text: modelData.label
                    font.pixelSize: 13
                    font.weight: root.currentValue === modelData.value ? Font.Medium : Font.Normal
                    color: root.currentValue === modelData.value ? modelData.activeColor : "#6B7280"
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.valueChanged(modelData.value)
            }
        }
    }
}
