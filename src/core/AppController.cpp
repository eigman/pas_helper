#include "AppController.h"
#include "ReportEngine.h"
#include "ReportParser.h"
#include "Storage.h"

#include <QDir>
#include <QTimer>

AppController::AppController(QObject* parent)
    : QObject(parent)
    , m_subsystemModel(new SubsystemModel(this))
    , m_pciModel(new PciDeviceModel(this))
    , m_workItemModel(new WorkItemModel(this))
{
    // Propagate subsystem changes as "modified"
    connect(m_subsystemModel, &QAbstractItemModel::dataChanged, this, [this]{ setModified(true); });
    connect(m_subsystemModel, &QAbstractItemModel::rowsInserted, this, [this]{ setModified(true); });
    connect(m_subsystemModel, &QAbstractItemModel::rowsRemoved, this, [this]{ setModified(true); });
}

void AppController::initialize(const QString& binaryDir)
{
    // Load presets
    const QString presetsPath = QDir(binaryDir).filePath(
        QStringLiteral("resources/presets/subsystems.json"));
    if (!m_presets.load(presetsPath)) {
        emit errorOccurred(QStringLiteral("Не удалось загрузить пресеты из ") + presetsPath);
    }

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
        m_workNotes = progress->workNotes;
        m_workItemModel->setItems(progress->workItems);
        emit workNotesChanged();
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

    // Save progress alongside
    ProgressData prog;
    prog.reportData = m_data;
    prog.workNotes  = m_workNotes;
    prog.workItems  = m_workItemModel->items();
    Storage::saveProgress(path, prog);

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
    m_workNotes.clear();
    m_currentFilePath.clear();
    m_workItemModel->setItems({});
    loadReportDataIntoModels(m_data);
    setModified(false);
    emit currentFilePathChanged();
    emit windowTitleChanged();
    emit deviceChanged();
    emit osInstallChanged();
    emit workNotesChanged();
    emit reportLoaded();
}

// ── Subsystem operations ─────────────────────────────────────────────────────

void AppController::addSubsystem(const QString& name)
{
    m_subsystemModel->addSubsystem(name);
    // Apply default checks from presets
    const int idx = m_subsystemModel->rowCount() - 1;
    const QStringList checks = m_presets.checksForSubsystem(name);
    if (!checks.isEmpty())
        m_subsystemModel->setCheckItems(idx, checks);
    setModified(true);
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
QStringList AppController::driverPresets()        const { return m_presets.drivers(); }
QStringList AppController::interfacePresets()     const { return m_presets.interfaces(); }
QStringList AppController::osInstallChecksPresets() const { return m_presets.osInstallChecks(); }

QStringList AppController::checksPresets(const QString& subsystemName) const
{
    return m_presets.checksForSubsystem(subsystemName);
}

QStringList AppController::testResultOptions() const
{
    return { QStringLiteral("успешно"), QStringLiteral("неуспешно"), QStringLiteral("частично") };
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

#undef SET_OS

void AppController::setRecommendations(const QString& v)
{
    if (m_data.recommendations == v) return;
    m_data.recommendations = v;
    setModified(true);
    emit recommendationsChanged();
}

void AppController::setWorkNotes(const QString& v)
{
    if (m_workNotes == v) return;
    m_workNotes = v;
    emit workNotesChanged();
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
    m_subsystemModel->setSubsystems(data.subsystems);
    emit deviceChanged();
    emit osInstallChanged();
    emit recommendationsChanged();
}

ReportData AppController::collectReportDataFromModels() const
{
    ReportData data = m_data;
    data.subsystems = m_subsystemModel->subsystems();
    return data;
}
