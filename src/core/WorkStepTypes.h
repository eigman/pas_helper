#pragma once

#include <QString>
#include <QList>

// Fixed checklist step from work_steps.json (read-only in UI).
struct WorkStepTemplate {
    QString id;
    QString title;
    QString overviewTag; // short label for summary export, e.g. "boot", "pci"
    QString instruction; // markdown-lite: ## headings, - bullets, ``` code
};

// Per-step user state persisted in .progress.json.
struct WorkStepState {
    QString status; // empty | Успешно | Условно успешно | Неуспешно
    QString note;
    QString tag;  // small marker: ticket, blocker, etc.
};

struct WorkProgressData {
    int currentIndex = 0;
    QList<WorkStepState> states; // same order as catalog; matched by index
};
