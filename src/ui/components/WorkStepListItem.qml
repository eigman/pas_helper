import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    property string title: ""
    property string status: ""
    property bool selected: false
    property int stepNumber: 0

    readonly property string _statusColor: {
        if (status === "Успешно")          return "#16A34A"
        if (status === "Условно успешно")  return "#D97706"
        if (status === "Неуспешно")        return "#DC2626"
        return "#E5E7EB"
    }

    signal clicked()

    implicitHeight: 44
    radius: 6
    color: selected ? "#E0F2FE" : (rowHover.containsMouse ? "#F3F4F6" : "white")
    border.color: selected ? "#0EA5E9" : "#E5E7EB"
    border.width: selected ? 1.5 : 1

    HoverHandler { id: rowHover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        Rectangle {
            width: 10
            height: 10
            radius: 5
            color: root._statusColor
            Layout.alignment: Qt.AlignVCenter
        }

        Label {
            Layout.fillWidth: true
            text: title
            font.pixelSize: 13
            font.weight: selected ? Font.Medium : Font.Normal
            color: "#111827"
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.WordWrap
        }
    }
}
