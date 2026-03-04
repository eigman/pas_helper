#pragma once

#include "ReportData.h"
#include "WorkItemModel.h"
#include <QString>
#include <QList>
#include <optional>

struct ProgressData {
    ReportData reportData;
    QString workNotes;
    QList<WorkItem> workItems;
};

// Handles reading and writing of:
//   - Report TXT files (via ReportEngine/ReportParser)
//   - Progress JSON files (filename.progress.json alongside the TXT)
class Storage {
public:
    // Read raw text from a .txt file
    static std::optional<QString> readTextFile(const QString& path);

    // Write text to a .txt file (overwrites)
    static bool writeTextFile(const QString& path, const QString& content);

    // Save/load progress JSON (form state + work tab data)
    static bool saveProgress(const QString& txtPath, const ProgressData& progress);
    static std::optional<ProgressData> loadProgress(const QString& txtPath);

    // Derive .progress.json path from a .txt report path
    static QString progressPath(const QString& txtPath);

private:
    static QJsonObject reportDataToJson(const ReportData& data);
    static ReportData reportDataFromJson(const QJsonObject& obj);
};
