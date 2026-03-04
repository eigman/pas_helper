#pragma once

#include "ReportData.h"
#include <QString>
#include <optional>

// Parses an existing .txt report file back into a ReportData struct.
// This allows opening and editing existing reports in the app.
class ReportParser {
public:
    // Parses the raw text content of a .txt report file.
    // Returns nullopt if the file structure is unrecognizable.
    static std::optional<ReportData> parse(const QString& text);

private:
    enum class Group { None, Device, Report, Tests, Recommendations };

    static void parseDeviceGroup(const QStringList& lines, ReportData& data);
    static void parseReportGroup(const QStringList& lines, ReportData& data);
    static void parseTestsGroup(const QStringList& lines, ReportData& data);

    // Splits a @tr line into cells separated by @|
    static QStringList splitTableRow(const QString& line);

    // Finds the subsystem by plainName, creates it if not found
    static SubsystemEntry* findOrCreateSubsystem(ReportData& data, const QString& plainName);
};
