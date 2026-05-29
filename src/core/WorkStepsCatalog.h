#pragma once

#include "WorkStepTypes.h"
#include <QString>
#include <QList>

class WorkStepsCatalog {
public:
    bool load(const QString& path);
    const QList<WorkStepTemplate>& steps() const { return m_steps; }

private:
    QList<WorkStepTemplate> m_steps;
};
