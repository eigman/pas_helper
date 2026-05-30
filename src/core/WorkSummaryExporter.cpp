#include "WorkSummaryExporter.h"

QString WorkSummaryExporter::toMarkdown(const QList<WorkStepTemplate>& catalog,
                                        const QList<WorkStepState>& states)
{
    QString out;
    out += QStringLiteral("# Сводка работ\n\n");

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
