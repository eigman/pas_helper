#include "RecommendationsConverter.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QVariantMap>

namespace {
QVariantList parseItems(const QStringList& lines, int& i, const QString& endTag)
{
    QVariantList items;
    while (i < lines.size()) {
        const QString line = lines.at(i).trimmed();
        if (line == endTag)
            break;
        if (line.startsWith(QLatin1String("@item ")))
            items << line.mid(6);
        ++i;
    }
    return items;
}
} // namespace

QString RecommendationsConverter::blocksToMarkup(const QVariantList& blocks)
{
    QString out;
    for (const QVariant& v : blocks) {
        const QVariantMap block = v.toMap();
        const QString type = block.value(QStringLiteral("type")).toString();

        if (type == QLatin1String("text")) {
            const QString text = block.value(QStringLiteral("text")).toString();
            if (!text.isEmpty()) {
                out += text;
                if (!out.endsWith(QLatin1Char('\n')))
                    out += QLatin1Char('\n');
                out += QLatin1Char('\n');
            }
        } else if (type == QLatin1String("ol")) {
            out += QLatin1String("@ol\n");
            const QVariantList items = block.value(QStringLiteral("items")).toList();
            for (const QVariant& item : items)
                out += QLatin1String("@item ") + item.toString() + QLatin1Char('\n');
            out += QLatin1String("@endol\n\n");
        } else if (type == QLatin1String("ul")) {
            out += QLatin1String("@ul\n");
            const QVariantList items = block.value(QStringLiteral("items")).toList();
            for (const QVariant& item : items)
                out += QLatin1String("@item ") + item.toString() + QLatin1Char('\n');
            out += QLatin1String("@endul\n\n");
        }
    }
    return out.trimmed();
}

QVariantList RecommendationsConverter::markupToBlocks(const QString& markup)
{
    QVariantList blocks;
    const QStringList lines = markup.split(QLatin1Char('\n'));
    int i = 0;

    auto flushText = [&](QString& buffer) {
        const QString t = buffer.trimmed();
        if (!t.isEmpty()) {
            QVariantMap block;
            block[QStringLiteral("type")] = QStringLiteral("text");
            block[QStringLiteral("text")] = t;
            blocks << block;
        }
        buffer.clear();
    };

    QString textBuffer;
    while (i < lines.size()) {
        const QString line = lines.at(i).trimmed();

        if (line.isEmpty()) {
            ++i;
            continue;
        }

        if (line == QLatin1String("@ol")) {
            flushText(textBuffer);
            ++i;
            QVariantMap block;
            block[QStringLiteral("type")] = QStringLiteral("ol");
            block[QStringLiteral("items")] = parseItems(lines, i, QStringLiteral("@endol"));
            blocks << block;
            if (i < lines.size() && lines.at(i).trimmed() == QLatin1String("@endol"))
                ++i;
            continue;
        }

        if (line == QLatin1String("@ul")) {
            flushText(textBuffer);
            ++i;
            QVariantMap block;
            block[QStringLiteral("type")] = QStringLiteral("ul");
            block[QStringLiteral("items")] = parseItems(lines, i, QStringLiteral("@endul"));
            blocks << block;
            if (i < lines.size() && lines.at(i).trimmed() == QLatin1String("@endul"))
                ++i;
            continue;
        }

        if (line.startsWith(QLatin1Char('@')))
            ++i;

        textBuffer += lines.at(i) + QLatin1Char('\n');
        ++i;
    }
    flushText(textBuffer);

    if (blocks.isEmpty() && !markup.trimmed().isEmpty()) {
        QVariantMap block;
        block[QStringLiteral("type")] = QStringLiteral("text");
        block[QStringLiteral("text")] = markup.trimmed();
        blocks << block;
    }

    return blocks;
}

QString RecommendationsConverter::blocksToJson(const QVariantList& blocks)
{
    QJsonArray arr;
    for (const QVariant& v : blocks) {
        const QVariantMap m = v.toMap();
        QJsonObject obj;
        obj[QStringLiteral("type")] = m.value(QStringLiteral("type")).toString();
        if (m.value(QStringLiteral("type")).toString() == QLatin1String("text"))
            obj[QStringLiteral("text")] = m.value(QStringLiteral("text")).toString();
        else {
            QJsonArray items;
            for (const QVariant& item : m.value(QStringLiteral("items")).toList())
                items.append(item.toString());
            obj[QStringLiteral("items")] = items;
        }
        arr.append(obj);
    }
    return QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

QVariantList RecommendationsConverter::jsonToBlocks(const QString& json)
{
    if (json.trimmed().isEmpty())
        return {};

    const QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (!doc.isArray())
        return {};

    QVariantList blocks;
    for (const QJsonValue& v : doc.array()) {
        const QJsonObject o = v.toObject();
        QVariantMap block;
        block[QStringLiteral("type")] = o.value(QLatin1String("type")).toString();
        if (o.value(QLatin1String("type")).toString() == QLatin1String("text"))
            block[QStringLiteral("text")] = o.value(QLatin1String("text")).toString();
        else {
            QVariantList items;
            for (const QJsonValue& item : o.value(QLatin1String("items")).toArray())
                items << item.toString();
            block[QStringLiteral("items")] = items;
        }
        blocks << block;
    }
    return blocks;
}

QString RecommendationsConverter::blocksToPlainText(const QVariantList& blocks)
{
    QString out;
    for (const QVariant& v : blocks) {
        const QVariantMap block = v.toMap();
        const QString type = block.value(QStringLiteral("type")).toString();

        if (type == QLatin1String("text")) {
            const QString text = block.value(QStringLiteral("text")).toString().trimmed();
            if (!text.isEmpty()) {
                if (!out.isEmpty())
                    out += QStringLiteral("\n\n");
                out += text;
            }
        } else if (type == QLatin1String("ol")) {
            if (!out.isEmpty())
                out += QStringLiteral("\n\n");
            const QVariantList items = block.value(QStringLiteral("items")).toList();
            for (int i = 0; i < items.size(); ++i) {
                const QString item = items.at(i).toString();
                if (!item.isEmpty())
                    out += QString::number(i + 1) + QLatin1String(". ") + item + QLatin1Char('\n');
            }
        } else if (type == QLatin1String("ul")) {
            if (!out.isEmpty())
                out += QStringLiteral("\n\n");
            const QVariantList items = block.value(QStringLiteral("items")).toList();
            for (const QVariant& item : items) {
                const QString t = item.toString();
                if (!t.isEmpty())
                    out += QStringLiteral("• ") + t + QLatin1Char('\n');
            }
        }
    }
    return out.trimmed();
}

QVariantList RecommendationsConverter::plainTextToBlocks(const QString& plain)
{
    QVariantList blocks;
    if (plain.trimmed().isEmpty())
        return blocks;

    static const QRegularExpression numberedRx(QStringLiteral("^(\\d+)\\.\\s*(.*)$"));
    static const QRegularExpression bulletRx(QStringLiteral("^[•\\-\\*]\\s*(.*)$"));

    QString textBuffer;
    QStringList olItems;
    QStringList ulItems;

    auto flushText = [&]() {
        const QString t = textBuffer.trimmed();
        if (!t.isEmpty()) {
            QVariantMap block;
            block[QStringLiteral("type")] = QStringLiteral("text");
            block[QStringLiteral("text")] = t;
            blocks << block;
        }
        textBuffer.clear();
    };

    auto flushOl = [&]() {
        QStringList nonEmpty;
        for (const QString& s : olItems) {
            if (!s.trimmed().isEmpty())
                nonEmpty << s.trimmed();
        }
        if (!nonEmpty.isEmpty()) {
            QVariantMap block;
            block[QStringLiteral("type")] = QStringLiteral("ol");
            QVariantList items;
            for (const QString& s : nonEmpty)
                items << s;
            block[QStringLiteral("items")] = items;
            blocks << block;
        }
        olItems.clear();
    };

    auto flushUl = [&]() {
        QStringList nonEmpty;
        for (const QString& s : ulItems) {
            if (!s.trimmed().isEmpty())
                nonEmpty << s.trimmed();
        }
        if (!nonEmpty.isEmpty()) {
            QVariantMap block;
            block[QStringLiteral("type")] = QStringLiteral("ul");
            QVariantList items;
            for (const QString& s : nonEmpty)
                items << s;
            block[QStringLiteral("items")] = items;
            blocks << block;
        }
        ulItems.clear();
    };

    enum class Mode { Text, Ol, Ul };
    Mode mode = Mode::Text;

    const QStringList lines = plain.split(QLatin1Char('\n'));
    for (const QString& rawLine : lines) {
        const QString line = rawLine.trimmed();

        if (line.isEmpty()) {
            if (mode == Mode::Ol) {
                flushOl();
                mode = Mode::Text;
            } else if (mode == Mode::Ul) {
                flushUl();
                mode = Mode::Text;
            } else {
                textBuffer += QLatin1Char('\n');
            }
            continue;
        }

        const auto numMatch = numberedRx.match(line);
        if (numMatch.hasMatch()) {
            if (mode == Mode::Ul)
                flushUl();
            if (mode == Mode::Text)
                flushText();
            // "1." after an existing numbered list → start a new list block
            if (mode == Mode::Ol && numMatch.captured(1).toInt() == 1 && !olItems.isEmpty())
                flushOl();
            mode = Mode::Ol;
            olItems << numMatch.captured(2).trimmed();
            continue;
        }

        const auto bulletMatch = bulletRx.match(line);
        if (bulletMatch.hasMatch()) {
            if (mode == Mode::Ol)
                flushOl();
            if (mode == Mode::Text)
                flushText();
            mode = Mode::Ul;
            ulItems << bulletMatch.captured(1).trimmed();
            continue;
        }

        if (mode == Mode::Ol)
            flushOl();
        if (mode == Mode::Ul)
            flushUl();
        mode = Mode::Text;
        if (!textBuffer.isEmpty() && !textBuffer.endsWith(QLatin1Char('\n')))
            textBuffer += QLatin1Char('\n');
        textBuffer += rawLine + QLatin1Char('\n');
    }

    if (mode == Mode::Ol)
        flushOl();
    else if (mode == Mode::Ul)
        flushUl();
    else
        flushText();

    if (blocks.isEmpty() && !plain.trimmed().isEmpty()) {
        QVariantMap block;
        block[QStringLiteral("type")] = QStringLiteral("text");
        block[QStringLiteral("text")] = plain.trimmed();
        blocks << block;
    }

    return blocks;
}
