import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// "?" icon — подсказка при наведении (светлое окно, не выходит за границы приложения).
Item {
    id: root

    property var examples: []
    property var sections: []
    property string popupTitle: "Подсказка"
    // "right" — окно справа от «?»; "left" — слева (если справа не помещается)
    property string popupSide: "right"
    readonly property int preferredPopupWidth: 460
    readonly property int minPopupWidth: 140
    readonly property int contentExtraPad: 16

    function lineWidth(text, pixelSize, weight) {
        lineMetrics.font.pixelSize = pixelSize
        lineMetrics.font.weight = weight
        lineMetrics.text = text
        return lineMetrics.advanceWidth
    }

    function measureContentWidth() {
        let w = 0
        const multi = root.displaySections.length > 1
        for (let i = 0; i < root.displaySections.length; ++i) {
            const s = root.displaySections[i]
            if (s.title && s.title.length > 0 && multi)
                w = Math.max(w, lineWidth(s.title, 12, Font.Medium))
            const ex = s.examples || []
            for (let j = 0; j < ex.length; ++j)
                w = Math.max(w, lineWidth("• " + ex[j], 14, Font.Normal))
        }
        return Math.ceil(w)
    }

    readonly property bool hasContent: {
        if (root.examples.length > 0)
            return true
        for (let i = 0; i < root.sections.length; ++i) {
            const block = root.sections[i]
            if (block && block.examples && block.examples.length > 0)
                return true
        }
        return false
    }

    readonly property var displaySections: {
        if (root.sections.length > 0)
            return root.sections
        if (root.examples.length > 0)
            return [{ title: root.popupTitle, examples: root.examples }]
        return []
    }

    implicitWidth: hasContent ? 20 : 0
    implicitHeight: hasContent ? 20 : 0

    TextMetrics {
        id: lineMetrics
        font.pixelSize: 14
    }

    Rectangle {
        anchors.centerIn: parent
        width: 16
        height: 16
        radius: 8
        color: helpHover.hovered ? "#F3F4F6" : "#F9FAFB"
        border.color: helpHover.hovered ? "#D1D5DB" : "#E5E7EB"
        border.width: 1

        Label {
            anchors.centerIn: parent
            text: "?"
            font.pixelSize: 10
            font.weight: Font.Medium
            color: helpHover.hovered ? "#374151" : "#6B7280"
        }
    }

    HoverHandler {
        id: helpHover
        onHoveredChanged: {
            if (hovered && root.hasContent)
                helpPopup.open()
            else
                helpPopup.close()
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        onClicked: {
            if (helpPopup.opened)
                helpPopup.close()
            else if (root.hasContent)
                helpPopup.open()
        }
    }

    Popup {
        id: helpPopup
        parent: Overlay.overlay
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 12

        onAboutToShow: {
            const margin = 12
            const overlay = Overlay.overlay
            if (!overlay)
                return
            const iconPos = root.mapToItem(overlay, 0, 0)
            const gap = 8

            const spaceRight = overlay.width - margin - (iconPos.x + root.width + gap)
            const spaceLeft = iconPos.x - margin - gap
            let side = root.popupSide
            let avail = side === "right" ? spaceRight : spaceLeft
            if (avail < root.minPopupWidth) {
                side = side === "right" ? "left" : "right"
                avail = side === "right" ? spaceRight : spaceLeft
            }
            const innerW = root.measureContentWidth() + root.contentExtraPad
            const popupPad = helpPopup.padding * 2
            helpPopup.width = Math.max(root.minPopupWidth,
                                      Math.min(root.preferredPopupWidth, avail, innerW + popupPad))

            let px
            if (side === "right") {
                px = iconPos.x + root.width + gap
            } else {
                px = iconPos.x - helpPopup.width - gap
            }
            let py = iconPos.y + root.height + 6

            if (px + helpPopup.width > overlay.width - margin)
                px = overlay.width - helpPopup.width - margin
            if (px < margin)
                px = margin

            if (py + helpPopup.height > overlay.height - margin)
                py = iconPos.y - helpPopup.height - 6
            if (py < margin)
                py = margin

            x = px
            y = py
        }

        background: Rectangle {
            color: "#FFFFFF"
            radius: 8
            border.color: "#E5E7EB"
            border.width: 1
        }

        Column {
            id: helpContent
            spacing: 8
            width: parent.width

            Repeater {
                id: sectionRepeater
                model: root.displaySections

                delegate: Column {
                    spacing: 4
                    width: helpContent.width

                    readonly property var blockExamples: modelData.examples || []

                    Label {
                        width: parent.width
                        visible: modelData.title && modelData.title.length > 0
                                 && sectionRepeater.count > 1
                        text: modelData.title
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: "#6B7280"
                    }

                    Repeater {
                        model: blockExamples
                        delegate: Label {
                            width: helpContent.width
                            text: "• " + modelData
                            font.pixelSize: 14
                            color: "#374151"
                            wrapMode: Text.Wrap
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        visible: sectionRepeater.count > 1
                                 && index < sectionRepeater.count - 1
                                 && blockExamples.length > 0
                        color: "#F3F4F6"
                    }
                }
            }
        }
    }
}
