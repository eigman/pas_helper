#include "WorkSummaryExporter.h"

static QString statusGlyph(const QString& status)
{
    if (status == QLatin1String("Успешно"))         return QStringLiteral("OK");
    if (status == QLatin1String("Условно успешно")) return QStringLiteral("~");
    if (status == QLatin1String("Неуспешно"))       return QStringLiteral("FAIL");
    return QStringLiteral("—");
}

QString WorkSummaryExporter::toMarkdown(const QList<WorkStepTemplate>& catalog,
                                        const QList<WorkStepState>& states)
{
    QString out;
    out += QStringLiteral("# Сводка работ\n\n");
    out += QStringLiteral("| # | Этап | Статус | Метка | Заметка |\n");
    out += QStringLiteral("|---|------|--------|-------|--------|\n");

    for (int i = 0; i < catalog.size(); ++i) {
        const auto& step = catalog.at(i);
        const WorkStepState state = i < states.size() ? states.at(i) : WorkStepState{};
        const QString tag = state.tag.isEmpty() ? QStringLiteral("—") : state.tag;
        QString note = state.note;
        note.replace(QLatin1Char('\n'), QLatin1String(" "));
        if (note.length() > 80)
            note = note.left(77) + QStringLiteral("...");
        if (note.isEmpty())
            note = QStringLiteral("—");

        out += QStringLiteral("| %1 | %2 | %3 %4 | %5 | %6 |\n")
                   .arg(i + 1)
                   .arg(step.title)
                   .arg(statusGlyph(state.status), state.status.isEmpty() ? QString() : state.status)
                   .arg(tag, note);
    }

    out += QStringLiteral("\n---\n\n");
    for (int i = 0; i < catalog.size(); ++i) {
        const auto& step = catalog.at(i);
        const WorkStepState state = i < states.size() ? states.at(i) : WorkStepState{};
        if (state.note.isEmpty() && state.status.isEmpty() && state.tag.isEmpty())
            continue;

        out += QStringLiteral("## %1. %2\n\n").arg(i + 1).arg(step.title);
        if (!state.status.isEmpty())
            out += QStringLiteral("**Статус:** %1\n\n").arg(state.status);
        if (!state.tag.isEmpty())
            out += QStringLiteral("**Метка:** %1\n\n").arg(state.tag);
        if (!state.note.isEmpty())
            out += QStringLiteral("%1\n\n").arg(state.note);
    }

    return out;
}
