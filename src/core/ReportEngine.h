#pragma once

#include "ReportData.h"
#include <QString>

// Generates the .txt report markup from a ReportData struct.
// The output must be consumed verbatim by the Jenkins report generator —
// any structural error (unclosed tag, missing group) breaks PDF generation.
class ReportEngine {
public:
    // Returns the full .txt content for the given report data.
    static QString generate(const ReportData& data);

private:
    static QString generateDeviceGroup(const ReportData& data);
    static QString generateReportGroup(const ReportData& data);
    static QString generateTestsGroup(const ReportData& data);
    static QString generateRecommendationsGroup(const ReportData& data);

    static QString termBlock(const QString& termName,
                             const QList<CheckItem>& checks,
                             const QString& result,
                             const QString& hintText,
                             const QString& cautionText);
};
