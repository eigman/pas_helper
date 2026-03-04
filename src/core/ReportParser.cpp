#include "ReportParser.h"
#include <QStringList>
#include <QRegularExpression>

std::optional<ReportData> ReportParser::parse(const QString& text)
{
    if (text.isEmpty()) return std::nullopt;

    ReportData data;
    const QStringList lines = text.split(QLatin1Char('\n'));

    // ── Parse @page line ───────────────────────────────────────────────────
    for (const QString& line : lines) {
        if (line.startsWith(QLatin1String("@page \"pas\""))) {
            // @page "pas" TITLE (заводской номер N)
            QString rest = line.mid(12).trimmed(); // after @page "pas"
            QRegularExpression re(QStringLiteral("^(.+?)\\s*\\(заводской номер\\s+(.+?)\\)\\s*$"));
            auto match = re.match(rest);
            if (match.hasMatch()) {
                data.device.pageTitle   = match.captured(1).trimmed();
                data.device.serialNumber = match.captured(2).trimmed();
            } else {
                data.device.pageTitle = rest;
            }
            break;
        }
    }

    // ── Split into group sections ──────────────────────────────────────────
    QStringList deviceLines, reportLines, testLines, recsLines;
    Group currentGroup = Group::None;

    for (const QString& line : lines) {
        if (line.trimmed() == QLatin1String("@group device")) {
            currentGroup = Group::Device; continue;
        } else if (line.trimmed() == QLatin1String("@group report")) {
            currentGroup = Group::Report; continue;
        } else if (line.trimmed() == QLatin1String("@group tests")) {
            currentGroup = Group::Tests; continue;
        } else if (line.trimmed() == QLatin1String("@group recomendations")) {
            currentGroup = Group::Recommendations; continue;
        }

        switch (currentGroup) {
        case Group::Device:          deviceLines << line; break;
        case Group::Report:          reportLines << line; break;
        case Group::Tests:           testLines   << line; break;
        case Group::Recommendations: recsLines   << line; break;
        default: break;
        }
    }

    if (deviceLines.isEmpty()) return std::nullopt;

    parseDeviceGroup(deviceLines, data);
    parseReportGroup(reportLines, data);
    parseTestsGroup(testLines, data);

    // Recommendations: collect all non-empty trailing content
    // Skip @latexonly lines
    QStringList recsFiltered;
    for (const QString& l : recsLines) {
        if (!l.trimmed().startsWith(QLatin1String("@latexonly"))) {
            recsFiltered << l;
        }
    }
    // Trim leading/trailing blank lines
    while (!recsFiltered.isEmpty() && recsFiltered.first().trimmed().isEmpty())
        recsFiltered.removeFirst();
    while (!recsFiltered.isEmpty() && recsFiltered.last().trimmed().isEmpty())
        recsFiltered.removeLast();
    data.recommendations = recsFiltered.join(QLatin1Char('\n'));

    return data;
}

void ReportParser::parseDeviceGroup(const QStringList& lines, ReportData& data)
{
    // Two @table blocks: first = device params, second = subsystems
    int tableIndex = 0;
    bool inTable = false;
    bool headerRow = true; // skip first @tr (column headers)

    for (const QString& line : lines) {
        const QString trimmed = line.trimmed();

        if (trimmed.startsWith(QLatin1String("@table["))) {
            inTable = true;
            headerRow = true;
            continue;
        }
        if (trimmed == QLatin1String("@endtable")) {
            inTable = false;
            ++tableIndex;
            continue;
        }

        if (inTable && trimmed.startsWith(QLatin1String("@tr "))) {
            if (headerRow) { headerRow = false; continue; } // skip header

            QStringList cells = splitTableRow(trimmed.mid(4)); // remove "@tr "
            if (tableIndex == 0) {
                // Device params: "@tr Label @| Value"
                if (cells.size() >= 2) {
                    const QString label = cells[0].trimmed();
                    const QString value = cells[1].trimmed();
                    if (label.contains(QLatin1String("Модель")))
                        data.device.model = value;
                    else if (label.contains(QLatin1String("Серийный")))
                        data.device.serialNumber = value;
                    else if (label.contains(QLatin1String("Материнская")))
                        data.device.motherboard = value;
                    else if (label.contains(QLatin1String("BIOS")))
                        data.device.bios = value;
                    else if (label.contains(QLatin1String("Процессор")))
                        data.device.processor = value;
                    else if (label.contains(QLatin1String("Чипсет")))
                        data.device.chipset = value;
                    else if (label.contains(QLatin1String("ОЗУ")))
                        data.device.ram = value;
                }
            } else if (tableIndex == 1) {
                // Subsystems: "@tr name @| controller @| interfaces @| driver"
                if (cells.size() >= 4) {
                    SubsystemEntry sub;
                    sub.name        = cells[0].trimmed();
                    sub.controller  = cells[1].trimmed();
                    sub.interfaces  = cells[2].trimmed();
                    sub.driver      = cells[3].trimmed();
                    data.subsystems << sub;
                }
            }
        }
    }
}

void ReportParser::parseReportGroup(const QStringList& lines, ReportData& data)
{
    bool inTable = false;
    bool headerRow = true;

    for (const QString& line : lines) {
        const QString trimmed = line.trimmed();
        if (trimmed.startsWith(QLatin1String("@table["))) { inTable = true; headerRow = true; continue; }
        if (trimmed == QLatin1String("@endtable")) { inTable = false; continue; }

        if (inTable && trimmed.startsWith(QLatin1String("@tr "))) {
            if (headerRow) { headerRow = false; continue; }

            QStringList cells = splitTableRow(trimmed.mid(4));
            if (cells.size() >= 3) {
                const QString name   = cells[0].trimmed();
                const QString result = cells[1].trimmed();
                const QString note   = cells[2].trimmed() == QLatin1String("-")
                                           ? QString()
                                           : cells[2].trimmed();

                if (name == QLatin1String("Установка и запуск ОС")) {
                    data.osInstall.testResult = result;
                    data.osInstall.testNote   = note;
                } else {
                    auto* sub = findOrCreateSubsystem(data, name);
                    if (sub) {
                        sub->testResult = result;
                        sub->testNote   = note;
                    }
                }
            }
        }
    }
}

void ReportParser::parseTestsGroup(const QStringList& lines, ReportData& data)
{
    // State machine to parse @dl ... @enddl block with @term/@use sub-blocks
    enum class State { Idle, InTerm, InUse, InUl, InHint, InCaution };
    State state = State::Idle;

    QString currentTermName;
    QList<CheckItem> currentChecks;
    QString currentResult;
    QString currentHint;
    QString currentCaution;

    auto flushTerm = [&]() {
        if (currentTermName.isEmpty()) return;

        if (currentTermName == QLatin1String("Установка и запуск ОС")) {
            data.osInstall.checkItems  = currentChecks;
            if (!currentResult.isEmpty()) data.osInstall.testResult = currentResult;
            data.osInstall.hintText    = currentHint;
            data.osInstall.cautionText = currentCaution;
        } else {
            auto* sub = findOrCreateSubsystem(data, currentTermName);
            if (sub) {
                sub->checkItems  = currentChecks;
                if (!currentResult.isEmpty()) sub->testResult = currentResult;
                sub->hintText    = currentHint;
                sub->cautionText = currentCaution;
            }
        }
        currentTermName.clear();
        currentChecks.clear();
        currentResult.clear();
        currentHint.clear();
        currentCaution.clear();
    };

    for (const QString& rawLine : lines) {
        const QString line    = rawLine;
        const QString trimmed = line.trimmed();

        if (trimmed == QLatin1String("@dl")) continue;
        if (trimmed == QLatin1String("@enddl")) { flushTerm(); break; }

        if (trimmed.startsWith(QLatin1String("@term "))) {
            flushTerm();
            currentTermName = trimmed.mid(6).trimmed();
            state = State::InTerm;
            continue;
        }

        if (trimmed.startsWith(QLatin1String("@use"))) {
            state = State::InUse;
            continue;
        }

        if (state == State::InUse || state == State::InUl) {
            if (trimmed == QLatin1String("@ul")) { state = State::InUl; continue; }
            if (trimmed == QLatin1String("@endul")) { state = State::InUse; continue; }

            if (state == State::InUl && trimmed.startsWith(QLatin1String("@item "))) {
                currentChecks << CheckItem{ trimmed.mid(6).trimmed() };
                continue;
            }

            if (trimmed.startsWith(QLatin1String("Результат проверки:"))) {
                currentResult = trimmed.mid(19).trimmed();
                continue;
            }

            if (trimmed == QLatin1String("@hint")) { state = State::InHint; continue; }
            if (trimmed == QLatin1String("@caution")) { state = State::InCaution; continue; }
        }

        if (state == State::InHint) {
            if (trimmed == QLatin1String("@endhint")) { state = State::InUse; continue; }
            if (!currentHint.isEmpty()) currentHint += QLatin1Char('\n');
            currentHint += trimmed;
            continue;
        }

        if (state == State::InCaution) {
            if (trimmed == QLatin1String("@endcaution")) { state = State::InUse; continue; }
            if (!currentCaution.isEmpty()) currentCaution += QLatin1Char('\n');
            currentCaution += trimmed;
            continue;
        }
    }
}

QStringList ReportParser::splitTableRow(const QString& rowContent)
{
    // Split on " @| " (with surrounding spaces)
    return rowContent.split(QStringLiteral(" @| "));
}

SubsystemEntry* ReportParser::findOrCreateSubsystem(ReportData& data, const QString& plainName)
{
    // Search by plain name (case-insensitive trimmed match)
    const QString target = plainName.trimmed().toLower();
    for (auto& sub : data.subsystems) {
        if (sub.plainName().toLower() == target) return &sub;
    }
    // Not found — create a stub (shouldn't happen in well-formed files)
    SubsystemEntry stub;
    stub.name = plainName;
    data.subsystems << stub;
    return &data.subsystems.last();
}
