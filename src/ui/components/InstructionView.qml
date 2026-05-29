import QtQuick
import QtQuick.Controls

Column {
    id: root
    spacing: 12
    width: parent ? parent.width : implicitWidth

    property string source: ""
    readonly property var blocks: parseBlocks(source)

    function parseBlocks(text) {
        const result = []
        if (!text)
            return result
        let inCode = false
        let codeLines = []
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line.startsWith("```")) {
                if (inCode) {
                    result.push({ type: "code", text: codeLines.join("\n") })
                    codeLines = []
                    inCode = false
                } else {
                    inCode = true
                }
                continue
            }
            if (inCode) {
                codeLines.push(line)
                continue
            }
            if (line.startsWith("## "))
                result.push({ type: "heading", text: line.substring(3) })
            else if (line.startsWith("- "))
                result.push({ type: "bullet", text: line.substring(2) })
            else if (line.trim() !== "")
                result.push({ type: "text", text: line })
        }
        if (inCode && codeLines.length)
            result.push({ type: "code", text: codeLines.join("\n") })

        // Одиночный пункт → без маркера
        for (let i = 0; i < result.length; i++) {
            if (result[i].type === "bullet") {
                const prevBullet = i > 0 && result[i - 1].type === "bullet"
                const nextBullet = i < result.length - 1 && result[i + 1].type === "bullet"
                if (!prevBullet && !nextBullet)
                    result[i] = { type: "text", text: result[i].text }
            }
        }
        return result
    }

    Repeater {
        model: root.blocks

        delegate: Item {
            width: root.width
            height: content.height

            Item {
                id: content
                width: parent.width
                height: heading.visible ? heading.implicitHeight
                      : (bulletRow.visible ? bulletRow.height
                      : (para.visible ? para.implicitHeight : codeItem.height))

                // Heading
                Label {
                    id: heading
                    width: parent.width
                    visible: modelData.type === "heading"
                    text: modelData.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: "#0F172A"
                    wrapMode: Text.WordWrap
                }

                // Bullet
                Row {
                    id: bulletRow
                    width: parent.width
                    visible: modelData.type === "bullet"
                    spacing: 8
                    height: bulletText.implicitHeight
                    Label {
                        text: "•"
                        font.pixelSize: 15
                        color: "#334155"
                    }
                    Label {
                        id: bulletText
                        width: parent.width - 22
                        text: modelData.text
                        font.pixelSize: 15
                        color: "#1E293B"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.5
                    }
                }

                // Plain text
                Label {
                    id: para
                    width: parent.width
                    visible: modelData.type === "text"
                    text: modelData.text
                    font.pixelSize: 15
                    color: "#1E293B"
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }

                // Code block — full width, horizontal scroll, no wrap
                Item {
                    id: codeItem
                    width: parent.width
                    height: codeRect.height
                    visible: modelData.type === "code"

                    Rectangle {
                        id: codeRect
                        width: parent.width
                        height: codeFlic.height + 22
                        radius: 6
                        color: "#EEF3F8"
                        border.color: "#C7D9EC"
                        border.width: 1
                        clip: true

                        Flickable {
                            id: codeFlic
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 11
                            height: codeText.implicitHeight
                            contentWidth: codeText.implicitWidth + 2
                            contentHeight: codeText.implicitHeight
                            flickableDirection: Flickable.HorizontalFlick
                            clip: false

                            Text {
                                id: codeText
                                text: modelData.text
                                font.family: "monospace"
                                font.pixelSize: 13
                                color: "#0F172A"
                                wrapMode: Text.NoWrap
                                lineHeight: 1.6
                            }
                        }
                    }
                }
            }
        }
    }
}
