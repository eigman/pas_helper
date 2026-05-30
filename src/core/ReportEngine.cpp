#include "ReportEngine.h"
#include "RecommendationsConverter.h"
#include <QTextStream>
#include <QRegularExpression>
#include <QStringList>

namespace {
QString normalizeSpaces(const QString& text)
{
    QString out = text;
    out.replace(QLatin1Char('\n'), QLatin1Char(' '));
    out.replace(QRegularExpression(QStringLiteral("\\s+")), QStringLiteral(" "));
    return out.trimmed();
}

QString wrapLineByWords(const QString& line, int maxChars)
{
    const QString source = normalizeSpaces(line);
    if (source.isEmpty() || maxChars <= 0)
        return source;

    QStringList words = source.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    if (words.isEmpty())
        return QString();

    QStringList lines;
    QString current;

    auto pushCurrent = [&]() {
        if (!current.isEmpty()) {
            lines << current;
            current.clear();
        }
    };

    for (const QString& word : words) {
        // No spaces in a long token (e.g. very long identifier) — force-wrap it.
        if (word.size() > maxChars) {
            pushCurrent();
            int pos = 0;
            while (pos < word.size()) {
                lines << word.mid(pos, maxChars);
                pos += maxChars;
            }
            continue;
        }

        if (current.isEmpty()) {
            current = word;
            continue;
        }

        if (current.size() + 1 + word.size() <= maxChars) {
            current += QStringLiteral(" ") + word;
        } else {
            pushCurrent();
            current = word;
        }
    }
    pushCurrent();
    return lines.join(QStringLiteral(" \\n "));
}

QString wrapCellPreservingBreaks(const QString& text, int maxChars)
{
    const QStringList rawLines = text.split(QRegularExpression(QStringLiteral("\\s*\\\\n\\s*")), Qt::SkipEmptyParts);
    QStringList wrappedLines;
    wrappedLines.reserve(rawLines.size());
    for (const QString& rawLine : rawLines) {
        const QString wrapped = wrapLineByWords(rawLine, maxChars);
        if (!wrapped.isEmpty())
            wrappedLines << wrapped;
    }
    return wrappedLines.isEmpty() ? QStringLiteral("-") : wrappedLines.join(QStringLiteral(" \\n "));
}

QStringList splitListItems(const QString& rawText, bool allowComma)
{
    QString normalized = rawText;
    normalized.replace(QStringLiteral("\\n"), QStringLiteral("\n"));
    normalized.replace(QLatin1Char(';'), QLatin1Char('\n'));
    if (allowComma)
        normalized.replace(QLatin1Char(','), QLatin1Char('\n'));

    const QStringList items = normalized.split(QRegularExpression(QStringLiteral("\\s*\n\\s*")), Qt::SkipEmptyParts);
    QStringList cleaned;
    cleaned.reserve(items.size());
    for (const QString& item : items) {
        const QString v = normalizeSpaces(item);
        if (!v.isEmpty())
            cleaned << v;
    }
    return cleaned;
}

QString controllerForExportSingle(const QString& rawController)
{
    const QString trimmed = normalizeSpaces(rawController);
    if (trimmed.isEmpty())
        return QStringLiteral("-");

    // Already in canonical report markup.
    static const QRegularExpression canonicalRe(
        QStringLiteral("^(.+?)\\s+\\\\n\\s*\\[\\*\\*([0-9a-fA-F]{4}:[0-9a-fA-F]{4})\\*\\*\\]$"));
    const auto canonicalMatch = canonicalRe.match(trimmed);
    if (canonicalMatch.hasMatch()) {
        const QString name = canonicalMatch.captured(1).trimmed();
        const QString ids = canonicalMatch.captured(2).toLower();
        return name + QStringLiteral(" \\n[**") + ids + QStringLiteral("**]");
    }

    // UI format: "Name [8086:7a62]" or "Name [**8086:7a62**]".
    static const QRegularExpression uiRe(
        QStringLiteral("^(.+?)\\s+\\[(?:\\*\\*)?([0-9a-fA-F]{4}:[0-9a-fA-F]{4})(?:\\*\\*)?\\]$"));
    const auto uiMatch = uiRe.match(trimmed);
    if (uiMatch.hasMatch()) {
        const QString name = uiMatch.captured(1).trimmed();
        const QString ids = uiMatch.captured(2).toLower();
        return name + QStringLiteral(" \\n[**") + ids + QStringLiteral("**]");
    }

    return trimmed;
}

QString controllerForExport(const QString& rawController)
{
    const QStringList controllers = splitListItems(rawController, false);
    if (controllers.isEmpty())
        return QStringLiteral("-");

    QStringList normalized;
    normalized.reserve(controllers.size());
    for (const QString& c : controllers) {
        normalized << controllerForExportSingle(c);
    }
    return wrapCellPreservingBreaks(normalized.join(QStringLiteral(" \\n ")), 46);
}

QString listForExport(const QString& rawValue, int wrapWidth)
{
    const QStringList items = splitListItems(rawValue, true);
    if (items.isEmpty())
        return QStringLiteral("-");
    return wrapCellPreservingBreaks(items.join(QStringLiteral(" \\n ")), wrapWidth);
}
}

QString ReportEngine::generate(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    // ── Header ──────────────────────────────────────────────────────────────
    s << "@page \"pas\" " << data.device.pageTitle
      << " (заводской номер " << data.device.serialNumber << ")\n\n";
    s << "@brief \n\n";
    s << "Отчет о проверке программно-аппаратной совместимости с OS_NAME ред. OS_VERSION.\n\n";
    s << "@par Содержание отчета:\n\n";
    s << "@@item Характеристика оборудования\n";
    s << "@@item Отчет о проверках\n";
    s << "@@item Детализация отчета\n";
    s << "@@item Рекомендации\n\n";

    s << generateDeviceGroup(data);
    s << generateReportGroup(data);
    s << generateTestsGroup(data);
    s << generateRecommendationsGroup(data);

    return out;
}

QString ReportEngine::generateDeviceGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "\n@group device\n\n";

    // Device parameters table (fixed 7 rows + header)
    s << "@table[width:40:60:width]\n";
    s << "@tr Технические параметры устройства @| Детализация\n";
    s << "@tr Модель                           @| " << data.device.model << "\n";
    s << "@tr Серийный/Заводской номер         @| " << data.device.serialNumber << "\n";
    s << "@tr Материнская плата                @| " << data.device.motherboard << "\n";
    s << "@tr Тип BIOS (версия)                @| " << data.device.bios << "\n";
    s << "@tr Процессор                        @| " << data.device.processor << "\n";
    s << "@tr Чипсет                           @| " << data.device.chipset << "\n";
    s << "@tr ОЗУ                              @| " << data.device.ram << "\n";
    s << "@endtable\n\n";

    // Subsystems table (dynamic rows)
    s << "@table[width:21:45:15:19:width]\n";
    s << "@tr Подсистема @| Контроллер @| Интерфейс(ы) @| Драйвер\n";
    for (const auto& sub : data.subsystems) {
        const QString ctrl = controllerForExport(sub.controller);
        const QString interfaces = listForExport(sub.interfaces, 22);
        const QString drivers = listForExport(sub.driver, 28);
        s << "@tr " << sub.name
          << " @| " << ctrl
          << " @| " << interfaces
          << " @| " << drivers << "\n";
    }
    s << "@endtable\n\n";

    s << "@latexonly \\newpage @endlatexonly\n\n\n\n";

    return out;
}

QString ReportEngine::generateReportGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "@group report\n\n";
    s << "@table[width:28:22:50:width]\n";
    s << "@tr Подсистема @| Результат проверки @| Примечание\n";

    // OS install — always first
    const QString osNote = data.osInstall.testNote.isEmpty()
                               ? QStringLiteral("-")
                               : data.osInstall.testNote;
    s << "@tr Установка и запуск ОС @| " << data.osInstall.testResult
      << " @| " << osNote << "\n";

    // Subsystems
    for (const auto& sub : data.subsystems) {
        const QString note = sub.testNote.isEmpty() ? QStringLiteral("-") : sub.testNote;
        s << "@tr " << sub.plainName()
          << " @| " << sub.testResult
          << " @| " << note << "\n";
    }
    s << "@endtable\n\n\n";

    return out;
}

QString ReportEngine::generateTestsGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "@group tests\n\n";
    s << "@dl\n";

    // OS install term (always first)
    s << termBlock(QStringLiteral("Установка и запуск ОС"),
                   data.osInstall.checkItems,
                   data.osInstall.testResult,
                   data.osInstall.hintText,
                   data.osInstall.cautionText,
                   data.osInstall.warningText);

    // Subsystem terms
    for (const auto& sub : data.subsystems) {
        s << termBlock(sub.plainName(),
                       sub.checkItems,
                       sub.testResult,
                       sub.hintText,
                       sub.cautionText,
                       sub.warningText);
    }

    s << "@enddl\n        \n\n";

    return out;
}

QString ReportEngine::generateRecommendationsGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "@group recomendations\n\n";
    QString recBody = data.recommendations;
    if (!data.recommendationsJson.isEmpty()) {
        const QVariantList blocks = RecommendationsConverter::jsonToBlocks(data.recommendationsJson);
        recBody = RecommendationsConverter::blocksToMarkup(blocks);
    }
    if (!recBody.isEmpty()) {
        s << recBody;
        if (!recBody.endsWith(QLatin1Char('\n'))) {
            s << "\n";
        }
    }

    return out;
}

QString ReportEngine::termBlock(const QString& termName,
                                const QList<CheckItem>& checks,
                                const QString& result,
                                const QString& hintText,
                                const QString& cautionText,
                                const QString& warningText)
{
    QString out;
    QTextStream s(&out);

    s << "@term " << termName << "\n";
    s << "@use Перечень проверок:\n";
    s << "    @ul\n";
    for (const auto& item : checks) {
        s << "    @item " << item.text << "\n";
    }
    s << "    @endul\n";
    s << "    Результат проверки: " << result << "\n";

    if (!hintText.isEmpty()) {
        s << "    @hint\n";
        s << "    " << hintText << "\n";
        s << "    @endhint\n";
    }
    if (!cautionText.isEmpty()) {
        s << "    @caution\n";
        s << "    " << cautionText << "\n";
        s << "    @endcaution\n";
    }
    if (!warningText.isEmpty()) {
        s << "    @warning\n";
        s << "    " << warningText << "\n";
        s << "    @endwarning\n";
    }

    s << "\n";
    return out;
}
