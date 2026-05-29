#include "Storage.h"
#include "WorkSummaryExporter.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QTextStream>

namespace {
QString normalizeTestResult(QString value)
{
    value = value.trimmed();
    if (value == QLatin1String("успешно"))
        return QStringLiteral("Успешно");
    if (value == QLatin1String("частично"))
        return QStringLiteral("Условно успешно");
    if (value == QLatin1String("неуспешно"))
        return QStringLiteral("Неуспешно");
    return value;
}
} // namespace

std::optional<QString> Storage::readTextFile(const QString& path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return std::nullopt;
    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);
    return in.readAll();
}

bool Storage::writeTextFile(const QString& path, const QString& content)
{
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    QTextStream out(&file);
    out.setEncoding(QStringConverter::Utf8);
    out << content;
    return true;
}

QString Storage::progressPath(const QString& txtPath)
{
    QFileInfo fi(txtPath);
    return fi.dir().filePath(fi.completeBaseName() + QStringLiteral(".progress.json"));
}

QString Storage::workSummaryPath(const QString& txtPath)
{
    QFileInfo fi(txtPath);
    return fi.dir().filePath(fi.completeBaseName() + QStringLiteral(".work.md"));
}

bool Storage::saveProgress(const QString& txtPath, const ProgressData& progress)
{
    QJsonObject root;
    root[QLatin1String("version")]    = 2;
    root[QLatin1String("reportData")] = reportDataToJson(progress.reportData);
    root[QLatin1String("workProgress")] = workProgressToJson(progress.workProgress, progress.workCurrentIndex);

    const QJsonDocument doc(root);
    QFile file(progressPath(txtPath));
    if (!file.open(QIODevice::WriteOnly)) return false;
    file.write(doc.toJson(QJsonDocument::Indented));
    return true;
}

std::optional<ProgressData> Storage::loadProgress(const QString& txtPath)
{
    QFile file(progressPath(txtPath));
    if (!file.exists() || !file.open(QIODevice::ReadOnly)) return std::nullopt;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return std::nullopt;

    const QJsonObject root = doc.object();
    ProgressData progress;
    progress.reportData = reportDataFromJson(root.value(QLatin1String("reportData")).toObject());
    progress.workProgress = workProgressFromJson(root);
    progress.workCurrentIndex = root.value(QLatin1String("workProgress"))
                                    .toObject()
                                    .value(QLatin1String("currentIndex"))
                                    .toInt(0);

    return progress;
}

QJsonObject Storage::workProgressToJson(const WorkProgressData& progress, int currentIndex)
{
    QJsonObject obj;
    obj[QLatin1String("version")]       = 1;
    obj[QLatin1String("currentIndex")]  = currentIndex;
    QJsonArray steps;
    for (const auto& state : progress.states) {
        QJsonObject s;
        s[QLatin1String("status")] = state.status;
        s[QLatin1String("note")]   = state.note;
        s[QLatin1String("tag")]    = state.tag;
        steps << s;
    }
    obj[QLatin1String("steps")] = steps;
    return obj;
}

WorkProgressData Storage::workProgressFromJson(const QJsonObject& root)
{
    WorkProgressData data;
    const QJsonObject wp = root.value(QLatin1String("workProgress")).toObject();
    if (wp.isEmpty())
        return data;

    const QJsonArray steps = wp.value(QLatin1String("steps")).toArray();
    for (const QJsonValue& v : steps) {
        const QJsonObject obj = v.toObject();
        data.states << WorkStepState{
            obj.value(QLatin1String("status")).toString(),
            obj.value(QLatin1String("note")).toString(),
            obj.value(QLatin1String("tag")).toString(),
        };
    }
    return data;
}

bool Storage::writeWorkSummary(const QString& txtPath,
                               const QList<WorkStepTemplate>& catalog,
                               const QList<WorkStepState>& states)
{
    const QString md = WorkSummaryExporter::toMarkdown(catalog, states);
    return writeTextFile(workSummaryPath(txtPath), md);
}

// ── JSON serialization helpers ───────────────────────────────────────────────

QJsonObject Storage::reportDataToJson(const ReportData& data)
{
    QJsonObject root;

    // Device params
    QJsonObject dev;
    dev[QLatin1String("pageTitle")]    = data.device.pageTitle;
    dev[QLatin1String("model")]        = data.device.model;
    dev[QLatin1String("serialNumber")] = data.device.serialNumber;
    dev[QLatin1String("motherboard")]  = data.device.motherboard;
    dev[QLatin1String("bios")]         = data.device.bios;
    dev[QLatin1String("processor")]    = data.device.processor;
    dev[QLatin1String("chipset")]      = data.device.chipset;
    dev[QLatin1String("ram")]          = data.device.ram;
    root[QLatin1String("device")] = dev;

    // OS install
    auto serializeEntry = [](const auto& e) -> QJsonObject {
        QJsonObject obj;
        obj[QLatin1String("testResult")]  = e.testResult;
        obj[QLatin1String("testNote")]    = e.testNote;
        obj[QLatin1String("hintText")]    = e.hintText;
        obj[QLatin1String("cautionText")] = e.cautionText;
        obj[QLatin1String("warningText")] = e.warningText;
        obj[QLatin1String("hintActive")]    = e.hintActive;
        obj[QLatin1String("cautionActive")] = e.cautionActive;
        obj[QLatin1String("warningActive")] = e.warningActive;
        QJsonArray checks;
        for (const auto& ci : e.checkItems) checks << ci.text;
        obj[QLatin1String("checkItems")] = checks;
        return obj;
    };
    root[QLatin1String("osInstall")] = serializeEntry(data.osInstall);

    // Subsystems
    QJsonArray subs;
    for (const auto& sub : data.subsystems) {
        QJsonObject obj = serializeEntry(sub);
        obj[QLatin1String("name")]       = sub.name;
        obj[QLatin1String("controller")] = sub.controller;
        obj[QLatin1String("interfaces")] = sub.interfaces;
        obj[QLatin1String("driver")]     = sub.driver;
        subs << obj;
    }
    root[QLatin1String("subsystems")]      = subs;
    root[QLatin1String("recommendations")]     = data.recommendations;
    root[QLatin1String("recommendationsJson")] = data.recommendationsJson;

    return root;
}

ReportData Storage::reportDataFromJson(const QJsonObject& root)
{
    ReportData data;

    const QJsonObject dev = root.value(QLatin1String("device")).toObject();
    data.device.pageTitle    = dev.value(QLatin1String("pageTitle")).toString();
    data.device.model        = dev.value(QLatin1String("model")).toString();
    data.device.serialNumber = dev.value(QLatin1String("serialNumber")).toString();
    data.device.motherboard  = dev.value(QLatin1String("motherboard")).toString();
    data.device.bios         = dev.value(QLatin1String("bios")).toString();
    data.device.processor    = dev.value(QLatin1String("processor")).toString();
    data.device.chipset      = dev.value(QLatin1String("chipset")).toString();
    data.device.ram          = dev.value(QLatin1String("ram")).toString();

    auto deserializeChecks = [](const QJsonObject& obj) -> QList<CheckItem> {
        QList<CheckItem> checks;
        const QJsonArray arr = obj.value(QLatin1String("checkItems")).toArray();
        for (const QJsonValue& v : arr) checks << CheckItem{ v.toString() };
        return checks;
    };

    const QJsonObject os = root.value(QLatin1String("osInstall")).toObject();
    data.osInstall.testResult  = normalizeTestResult(
        os.value(QLatin1String("testResult")).toString(QStringLiteral("Успешно")));
    data.osInstall.testNote    = os.value(QLatin1String("testNote")).toString();
    data.osInstall.hintText    = os.value(QLatin1String("hintText")).toString();
    data.osInstall.cautionText = os.value(QLatin1String("cautionText")).toString();
    data.osInstall.warningText = os.value(QLatin1String("warningText")).toString();
    data.osInstall.hintActive    = os.value(QLatin1String("hintActive")).toBool(!data.osInstall.hintText.isEmpty());
    data.osInstall.cautionActive = os.value(QLatin1String("cautionActive")).toBool(!data.osInstall.cautionText.isEmpty());
    data.osInstall.warningActive = os.value(QLatin1String("warningActive")).toBool(!data.osInstall.warningText.isEmpty());
    data.osInstall.checkItems  = deserializeChecks(os);

    const QJsonArray subs = root.value(QLatin1String("subsystems")).toArray();
    for (const QJsonValue& v : subs) {
        const QJsonObject obj = v.toObject();
        SubsystemEntry sub;
        sub.name        = obj.value(QLatin1String("name")).toString();
        sub.controller  = obj.value(QLatin1String("controller")).toString();
        sub.interfaces  = obj.value(QLatin1String("interfaces")).toString();
        sub.driver      = obj.value(QLatin1String("driver")).toString();
        sub.testResult  = normalizeTestResult(
            obj.value(QLatin1String("testResult")).toString(QStringLiteral("Успешно")));
        sub.testNote    = obj.value(QLatin1String("testNote")).toString();
        sub.hintText    = obj.value(QLatin1String("hintText")).toString();
        sub.cautionText = obj.value(QLatin1String("cautionText")).toString();
        sub.warningText = obj.value(QLatin1String("warningText")).toString();
        sub.hintActive    = obj.value(QLatin1String("hintActive")).toBool(!sub.hintText.isEmpty());
        sub.cautionActive = obj.value(QLatin1String("cautionActive")).toBool(!sub.cautionText.isEmpty());
        sub.warningActive = obj.value(QLatin1String("warningActive")).toBool(!sub.warningText.isEmpty());
        sub.checkItems  = deserializeChecks(obj);
        data.subsystems << sub;
    }

    data.recommendations     = root.value(QLatin1String("recommendations")).toString();
    data.recommendationsJson = root.value(QLatin1String("recommendationsJson")).toString();
    return data;
}
