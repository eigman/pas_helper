#pragma once

#include "WorkStepTypes.h"
#include <QString>
#include <QList>

class WorkSummaryExporter {
public:
    static QString toMarkdown(const QList<WorkStepTemplate>& catalog,
                              const QList<WorkStepState>& states);
};
