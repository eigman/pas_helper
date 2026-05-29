#include "AppController.h"
#include "ReportEngine.h"
#include "ReportParser.h"
#include "Storage.h"
#include "RecommendationsConverter.h"

#include <QDir>
#include <QTimer>

AppController::AppController(QObject* parent)
    : QObject(parent)
    , m_subsystemModel(new SubsystemModel(this))
    , m_pciModel(new PciDeviceModel(this))
    , m_workStepModel(new WorkStepModel(this))
{
    connect(m_subsystemModel, &QAbstractItemModel::dataChanged, this, [this]{ setModified(true); });
    connect(m_subsystemModel, &QAbstractItemModel::rowsInserted, this, [this]{ setModified(true); });
    connect(m_subsystemModel, &QAbstractItemModel::rowsRemoved, this, [this]{ setModified(true); });
    connect(m_workStepModel, &WorkStepModel::stepDataChanged, this, [this]{ setModified(true); });
}

void AppController::initialize(const QString& binaryDir)
{
    // Load presets
    const QString presetsPath = QDir(binaryDir).filePath(
        QStringLiteral("resources/presets/subsystems.json"));
    if (!m_presets.load(presetsPath)) {
        emit errorOccurred(QStringLiteral("Не удалось загрузить пресеты из ") + presetsPath);
    }

    const QString examplesPath = QDir(binaryDir).filePath(
        QStringLiteral("resources/presets/field_examples.json"));
    if (!m_examples.load(examplesPath)) {
        emit errorOccurred(QStringLiteral("Не удалось загрузить примеры из ") + examplesPath);
    }

    const QString workStepsPath = QDir(binaryDir).filePath(
        QStringLiteral("resources/presets/work_steps.json"));
    if (!m_workStepsCatalog.load(workStepsPath)) {
        emit errorOccurred(QStringLiteral("Не удалось загрузить этапы работ из ") + workStepsPath);
    } else {
        m_workStepModel->setCatalog(m_workStepsCatalog.steps());
        emit workStepCountChanged();
    }

    // Add all preset subsystems by default
    for (const QString& name : m_presets.subsystemNames())
        addSubsystem(name);

    m_data.osInstall.checkItems.clear();
    for (const QString& text : m_presets.defaultOsInstallChecks())
        m_data.osInstall.checkItems << CheckItem{ text };

    setModified(false); // fresh state, not dirty
    emit osInstallChanged();

    // Load pci.ids
    m_pciAnalyzer.loadPciIds(binaryDir);
    emit pciStatusChanged();
}

// ── File operations ──────────────────────────────────────────────────────────

bool AppController::openFile(const QString& path)
{
    // Try loading progress.json first (has full form state)
    auto progress = Storage::loadProgress(path);
    if (progress) {
        loadReportDataIntoModels(progress->reportData);
        loadWorkProgress(progress->workProgress, progress->workCurrentIndex);
    } else {
        // Fall back to parsing the TXT file
        auto text = Storage::readTextFile(path);
        if (!text) {
            emit errorOccurred(QStringLiteral("Не удалось открыть файл: ") + path);
            return false;
        }
        auto parsed = ReportParser::parse(*text);
        if (!parsed) {
            emit errorOccurred(QStringLiteral("Не удалось разобрать файл отчёта: ") + path);
            return false;
        }
        loadReportDataIntoModels(*parsed);
        resetWorkProgress();
    }

    m_currentFilePath = path;
    setModified(false);
    emit currentFilePathChanged();
    emit windowTitleChanged();
    emit reportLoaded();
    return true;
}

bool AppController::saveFile()
{
    if (m_currentFilePath.isEmpty()) return false;
    return saveFileAs(m_currentFilePath);
}

bool AppController::saveFileAs(const QString& path)
{
    m_data = collectReportDataFromModels();
    const QString txt = ReportEngine::generate(m_data);
    if (!Storage::writeTextFile(path, txt)) {
        emit errorOccurred(QStringLiteral("Не удалось сохранить файл: ") + path);
        return false;
    }

    ProgressData prog = collectProgressData();
    prog.reportData = m_data;
    Storage::saveProgress(path, prog);
    Storage::writeWorkSummary(path, m_workStepsCatalog.steps(), prog.workProgress.states);

    m_currentFilePath = path;
    setModified(false);
    emit currentFilePathChanged();
    emit windowTitleChanged();
    return true;
}

bool AppController::exportTxt(const QString& path)
{
    m_data = collectReportDataFromModels();
    const QString txt = ReportEngine::generate(m_data);
    if (!Storage::writeTextFile(path, txt)) {
        emit errorOccurred(QStringLiteral("Не удалось экспортировать: ") + path);
        return false;
    }
    return true;
}

void AppController::newReport()
{
    m_data = ReportData{};
    m_currentFilePath.clear();
    loadReportDataIntoModels(m_data);
    resetWorkProgress();
    setModified(false);
    emit currentFilePathChanged();
    emit windowTitleChanged();
    emit deviceChanged();
    emit osInstallChanged();
    emit reportLoaded();
}

// ── Subsystem operations ─────────────────────────────────────────────────────

void AppController::addSubsystem(const QString& name)
{
    const QStringList presetOrder = m_presets.subsystemNames();
    auto presetRank = [&](const QString& subsystemName) -> int {
        const int r = presetOrder.indexOf(subsystemName);
        return r >= 0 ? r : 0x7fffffff;
    };
    const int newRank = presetRank(name);
    int insertAt = m_subsystemModel->rowCount();
    for (int i = 0; i < m_subsystemModel->rowCount(); ++i) {
        const QString existing = m_subsystemModel->subsystems().at(i).name;
        if (presetRank(existing) > newRank) {
            insertAt = i;
            break;
        }
    }

    m_subsystemModel->insertSubsystem(insertAt, name);
    const SubsystemPreset preset = m_presets.presetForSubsystem(name);
    if (!preset.defaultChecks.isEmpty())
        m_subsystemModel->setCheckItems(insertAt, preset.defaultChecks);
    if (!preset.icon.isEmpty())
        m_subsystemModel->setField(insertAt, QStringLiteral("icon"), preset.icon);
    if (!preset.defaultController.isEmpty())
        m_subsystemModel->setField(insertAt, QStringLiteral("controller"), preset.defaultController);
    if (!preset.defaultInterfaces.isEmpty())
        m_subsystemModel->setField(insertAt, QStringLiteral("interfaces"), preset.defaultInterfaces);
    if (!preset.defaultDriver.isEmpty())
        m_subsystemModel->setField(insertAt, QStringLiteral("driver"), preset.defaultDriver);
}

void AppController::removeSubsystem(int index)
{
    m_subsystemModel->removeSubsystem(index);
}

// ── PCI operations ───────────────────────────────────────────────────────────

void AppController::parsePciDump(const QString& dumpText)
{
    const QList<PciDevice> devices = m_pciAnalyzer.parseDump(dumpText);
    m_pciModel->setDevices(devices);
}

void AppController::assignPciToSubsystem(int pciIndex, int subsystemIndex)
{
    const PciDevice dev = m_pciModel->deviceAt(pciIndex);
    if (dev.vendorId.isEmpty()) return;

    m_subsystemModel->setField(subsystemIndex,
                               QStringLiteral("controller"),
                               dev.controllerString());
    setModified(true);
}

// ── OS Install check items ────────────────────────────────────────────────────

void AppController::addOsCheckItem(const QString& text)
{
    m_data.osInstall.checkItems << CheckItem{ text };
    setModified(true);
    emit osInstallChanged();
}

void AppController::removeOsCheckItem(int index)
{
    if (index < 0 || index >= m_data.osInstall.checkItems.size()) return;
    m_data.osInstall.checkItems.removeAt(index);
    setModified(true);
    emit osInstallChanged();
}

void AppController::setOsCheckItem(int index, const QString& text)
{
    if (index < 0 || index >= m_data.osInstall.checkItems.size()) return;
    m_data.osInstall.checkItems[index].text = text;
    setModified(true);
    emit osInstallChanged();
}


// ── Presets ──────────────────────────────────────────────────────────────────

QStringList AppController::subsystemNamePresets() const { return m_presets.subsystemNames(); }
QString     AppController::iconForSubsystem(const QString& name) const { return m_presets.iconForSubsystem(name); }
QStringList AppController::driverPresets() const { return m_presets.drivers(); }
QStringList AppController::interfacePresets() const { return m_presets.interfaces(); }

QStringList AppController::driverPresetsForSubsystem(int subsystemIndex) const
{
    if (subsystemIndex < 0 || subsystemIndex >= m_subsystemModel->rowCount())
        return m_presets.drivers();
    const auto subs = m_subsystemModel->subsystems();
    const QString icon = subs.at(subsystemIndex).icon.isEmpty()
                             ? m_presets.iconForSubsystem(subs.at(subsystemIndex).name)
                             : subs.at(subsystemIndex).icon;
    return m_presets.driversForIcon(icon);
}

QStringList AppController::interfacePresetsForSubsystem(int subsystemIndex) const
{
    if (subsystemIndex < 0 || subsystemIndex >= m_subsystemModel->rowCount())
        return m_presets.interfaces();
    const auto subs = m_subsystemModel->subsystems();
    const QString icon = subs.at(subsystemIndex).icon.isEmpty()
                             ? m_presets.iconForSubsystem(subs.at(subsystemIndex).name)
                             : subs.at(subsystemIndex).icon;
    return m_presets.interfacesForIcon(icon);
}

QString AppController::fieldPlaceholder(const QString& scope, const QString& fieldKey,
                                        const QString& contextKey) const
{
    return m_examples.placeholder(scope, fieldKey, contextKey);
}

QStringList AppController::fieldExamples(const QString& scope, const QString& fieldKey,
                                         const QString& contextKey) const
{
    return m_examples.examples(scope, fieldKey, contextKey);
}
QStringList AppController::osInstallChecksPresets() const { return m_presets.osInstallChecks(); }

QStringList AppController::checksPresets(const QString& subsystemName) const
{
    return m_presets.checksForSubsystem(subsystemName);
}

QStringList AppController::testResultOptions() const
{
    return { QStringLiteral("Успешно"),
             QStringLiteral("Условно успешно"),
             QStringLiteral("Неуспешно") };
}

// ── Property helpers ─────────────────────────────────────────────────────────

QString AppController::windowTitle() const
{
    QString title = m_currentFilePath.isEmpty()
                        ? QStringLiteral("Новый отчёт")
                        : m_currentFilePath.split(QLatin1Char('/')).last();
    if (m_modified) title += QStringLiteral(" *");
    return title;
}

QStringList AppController::osCheckItems() const
{
    QStringList list;
    for (const auto& ci : m_data.osInstall.checkItems) list << ci.text;
    return list;
}

QString AppController::pciStatusMessage() const
{
    return m_pciAnalyzer.isPciIdsLoaded()
               ? QStringLiteral("pci.ids загружен")
               : QStringLiteral("pci.ids не найден — названия устройств недоступны");
}

// ── Property setters ─────────────────────────────────────────────────────────

#define SET_DEVICE(field, member)                         \
    void AppController::set##field(const QString& v) {    \
        if (m_data.device.member == v) return;            \
        m_data.device.member = v;                         \
        setModified(true);                                \
        emit deviceChanged();                             \
    }

SET_DEVICE(DevicePageTitle,   pageTitle)
SET_DEVICE(DeviceModel,       model)
SET_DEVICE(DeviceSerial,      serialNumber)
SET_DEVICE(DeviceMotherboard, motherboard)
SET_DEVICE(DeviceBios,        bios)
SET_DEVICE(DeviceProcessor,   processor)
SET_DEVICE(DeviceChipset,     chipset)
SET_DEVICE(DeviceRam,         ram)

#undef SET_DEVICE

#define SET_OS(field, member)                              \
    void AppController::setOs##field(const QString& v) {  \
        if (m_data.osInstall.member == v) return;         \
        m_data.osInstall.member = v;                      \
        setModified(true);                                \
        emit osInstallChanged();                          \
    }

SET_OS(TestResult,  testResult)
SET_OS(TestNote,    testNote)
SET_OS(HintText,    hintText)
SET_OS(CautionText, cautionText)
SET_OS(WarningText, warningText)

#undef SET_OS

QString AppController::recommendationsText() const
{
    return RecommendationsConverter::blocksToPlainText(m_recommendationBlocks);
}

void AppController::setRecommendationBlocks(const QVariantList& blocks)
{
    m_recommendationBlocks = blocks;
    m_data.recommendationsJson = RecommendationsConverter::blocksToJson(blocks);
    m_data.recommendations = RecommendationsConverter::blocksToMarkup(blocks);
    setModified(true);
    emit recommendationBlocksChanged();
    emit recommendationsTextChanged();
}

void AppController::setRecommendationsText(const QString& v)
{
    setRecommendationBlocks(RecommendationsConverter::plainTextToBlocks(v));
}

void AppController::setCurrentWorkStepIndex(int index)
{
    const int maxIdx = qMax(0, m_workStepModel->rowCount() - 1);
    const int clamped = qBound(0, index, maxIdx);
    if (m_currentWorkStepIndex == clamped) return;
    m_currentWorkStepIndex = clamped;
    emit currentWorkStepIndexChanged();
}

void AppController::nextWorkStep()
{
    setCurrentWorkStepIndex(m_currentWorkStepIndex + 1);
}

void AppController::prevWorkStep()
{
    setCurrentWorkStepIndex(m_currentWorkStepIndex - 1);
}

void AppController::goToWorkStep(int index)
{
    setCurrentWorkStepIndex(index);
}

// ── Internal ─────────────────────────────────────────────────────────────────

void AppController::setModified(bool v)
{
    if (m_modified == v) return;
    m_modified = v;
    emit isModifiedChanged();
    emit windowTitleChanged();
}

void AppController::loadReportDataIntoModels(const ReportData& data)
{
    m_data = data;
    QList<SubsystemEntry> subsystems = data.subsystems;
    for (auto& sub : subsystems) {
        sub.icon = m_presets.iconForSubsystem(sub.name);
        if (!sub.hintText.isEmpty() && !sub.hintActive)
            sub.hintActive = true;
        if (!sub.cautionText.isEmpty() && !sub.cautionActive)
            sub.cautionActive = true;
        if (!sub.warningText.isEmpty() && !sub.warningActive)
            sub.warningActive = true;
    }
    m_subsystemModel->setSubsystems(subsystems);

    if (!m_data.recommendationsJson.isEmpty())
        m_recommendationBlocks = RecommendationsConverter::jsonToBlocks(m_data.recommendationsJson);
    else if (!m_data.recommendations.isEmpty())
        m_recommendationBlocks = RecommendationsConverter::markupToBlocks(m_data.recommendations);
    else
        m_recommendationBlocks.clear();

    emit deviceChanged();
    emit osInstallChanged();
    emit recommendationBlocksChanged();
    emit recommendationsTextChanged();
}

ReportData AppController::collectReportDataFromModels() const
{
    ReportData data = m_data;
    data.subsystems = m_subsystemModel->subsystems();
    data.recommendationsJson = RecommendationsConverter::blocksToJson(m_recommendationBlocks);
    data.recommendations = RecommendationsConverter::blocksToMarkup(m_recommendationBlocks);
    return data;
}

void AppController::loadWorkProgress(const WorkProgressData& progress, int currentIndex)
{
    m_workStepModel->applyProgress(progress);
    setCurrentWorkStepIndex(currentIndex);
}

ProgressData AppController::collectProgressData() const
{
    ProgressData prog;
    prog.workProgress = m_workStepModel->progressData();
    prog.workCurrentIndex = m_currentWorkStepIndex;
    return prog;
}

void AppController::resetWorkProgress()
{
    m_workStepModel->resetStates();
    setCurrentWorkStepIndex(0);
}
