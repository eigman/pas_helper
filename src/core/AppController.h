#pragma once

#include "ReportData.h"
#include "SubsystemModel.h"
#include "PciDeviceModel.h"
#include "WorkStepModel.h"
#include "WorkStepsCatalog.h"
#include "Storage.h"
#include "PciAnalyzer.h"
#include "PresetManager.h"
#include "ExamplesManager.h"

#include <QObject>
#include <QTimer>
#include <QString>
#include <QStringList>

// Main bridge between QML and all C++ logic.
// Exposed to QML as context property "controller".
class AppController : public QObject {
    Q_OBJECT

    // ── File state ───────────────────────────────────────────────────────────
    Q_PROPERTY(QString currentFilePath READ currentFilePath NOTIFY currentFilePathChanged)
    Q_PROPERTY(bool isModified READ isModified NOTIFY isModifiedChanged)
    Q_PROPERTY(QString windowTitle READ windowTitle NOTIFY windowTitleChanged)

    // ── Device params ────────────────────────────────────────────────────────
    Q_PROPERTY(QString devicePageTitle   READ devicePageTitle   WRITE setDevicePageTitle   NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceModel       READ deviceModel       WRITE setDeviceModel       NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceSerial      READ deviceSerial      WRITE setDeviceSerial      NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceMotherboard READ deviceMotherboard WRITE setDeviceMotherboard NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceBios        READ deviceBios        WRITE setDeviceBios        NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceProcessor   READ deviceProcessor   WRITE setDeviceProcessor   NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceChipset     READ deviceChipset     WRITE setDeviceChipset     NOTIFY deviceChanged)
    Q_PROPERTY(QString deviceRam         READ deviceRam         WRITE setDeviceRam         NOTIFY deviceChanged)

    // ── OS Install ───────────────────────────────────────────────────────────
    Q_PROPERTY(QString osTestResult  READ osTestResult  WRITE setOsTestResult  NOTIFY osInstallChanged)
    Q_PROPERTY(QString osTestNote    READ osTestNote    WRITE setOsTestNote    NOTIFY osInstallChanged)
    Q_PROPERTY(QStringList osCheckItems READ osCheckItems NOTIFY osInstallChanged)
    Q_PROPERTY(QString osHintText    READ osHintText    WRITE setOsHintText    NOTIFY osInstallChanged)
    Q_PROPERTY(QString osCautionText READ osCautionText WRITE setOsCautionText NOTIFY osInstallChanged)
    Q_PROPERTY(QString osWarningText READ osWarningText WRITE setOsWarningText NOTIFY osInstallChanged)

    // ── Models ───────────────────────────────────────────────────────────────
    Q_PROPERTY(SubsystemModel*  subsystemModel READ subsystemModel  CONSTANT)
    Q_PROPERTY(PciDeviceModel*  pciModel       READ pciModel        CONSTANT)
    Q_PROPERTY(WorkStepModel*   workStepModel       READ workStepModel       CONSTANT)
    Q_PROPERTY(int             currentWorkStepIndex READ currentWorkStepIndex WRITE setCurrentWorkStepIndex NOTIFY currentWorkStepIndexChanged)
    Q_PROPERTY(int             workStepCount        READ workStepCount        NOTIFY workStepCountChanged)

    // ── Recommendations ──────────────────────────────────────────────────────
    Q_PROPERTY(QVariantList recommendationBlocks READ recommendationBlocks WRITE setRecommendationBlocks NOTIFY recommendationBlocksChanged)
    Q_PROPERTY(QString recommendationsText READ recommendationsText WRITE setRecommendationsText NOTIFY recommendationsTextChanged)

    // ── PCI status ───────────────────────────────────────────────────────────
    Q_PROPERTY(bool pciIdsLoaded READ pciIdsLoaded NOTIFY pciStatusChanged)
    Q_PROPERTY(QString pciStatusMessage READ pciStatusMessage NOTIFY pciStatusChanged)

public:
    explicit AppController(QObject* parent = nullptr);

    void initialize(const QString& binaryDir);

    // ── File operations ──────────────────────────────────────────────────────
    Q_INVOKABLE bool openFile(const QString& path);
    Q_INVOKABLE bool saveFile();
    Q_INVOKABLE bool saveFileAs(const QString& path);
    Q_INVOKABLE bool exportTxt(const QString& path);
    Q_INVOKABLE bool createNewProject(const QString& selectedPath);

    // ── Subsystem operations ─────────────────────────────────────────────────
    Q_INVOKABLE void addSubsystem(const QString& name);
    Q_INVOKABLE void removeSubsystem(int index);

    // ── PCI operations ───────────────────────────────────────────────────────
    Q_INVOKABLE void parsePciDump(const QString& dumpText);
    Q_INVOKABLE void assignPciToSubsystem(int pciIndex, int subsystemIndex);

    // ── OS Install check items ────────────────────────────────────────────────
    Q_INVOKABLE void addOsCheckItem(const QString& text);
    Q_INVOKABLE void removeOsCheckItem(int index);
    Q_INVOKABLE void setOsCheckItem(int index, const QString& text);

    // ── Presets ──────────────────────────────────────────────────────────────
    Q_INVOKABLE QStringList subsystemNamePresets() const;
    Q_INVOKABLE QString     iconForSubsystem(const QString& name) const;
    Q_INVOKABLE QStringList driverPresets() const;
    Q_INVOKABLE QStringList interfacePresets() const;
    Q_INVOKABLE QStringList driverPresetsForSubsystem(int subsystemIndex) const;
    Q_INVOKABLE QStringList interfacePresetsForSubsystem(int subsystemIndex) const;
    Q_INVOKABLE QString fieldPlaceholder(const QString& scope, const QString& fieldKey,
                                         const QString& contextKey = {}) const;
    Q_INVOKABLE QStringList fieldExamples(const QString& scope, const QString& fieldKey,
                                          const QString& contextKey = {}) const;
    Q_INVOKABLE QStringList checksPresets(const QString& subsystemName) const;
    Q_INVOKABLE QStringList osInstallChecksPresets() const;
    Q_INVOKABLE QStringList testResultOptions() const;

    // ── Work tab navigation ───────────────────────────────────────────────────
    Q_INVOKABLE void nextWorkStep();
    Q_INVOKABLE void prevWorkStep();
    Q_INVOKABLE void goToWorkStep(int index);

    // ── Property getters ─────────────────────────────────────────────────────
    QString currentFilePath()   const { return m_currentFilePath; }
    bool    isModified()        const { return m_modified; }
    QString windowTitle()       const;

    QString devicePageTitle()   const { return m_data.device.pageTitle; }
    QString deviceModel()       const { return m_data.device.model; }
    QString deviceSerial()      const { return m_data.device.serialNumber; }
    QString deviceMotherboard() const { return m_data.device.motherboard; }
    QString deviceBios()        const { return m_data.device.bios; }
    QString deviceProcessor()   const { return m_data.device.processor; }
    QString deviceChipset()     const { return m_data.device.chipset; }
    QString deviceRam()         const { return m_data.device.ram; }

    QString    osTestResult()   const { return m_data.osInstall.testResult; }
    QString    osTestNote()     const { return m_data.osInstall.testNote; }
    QStringList osCheckItems()  const;
    QString    osHintText()     const { return m_data.osInstall.hintText; }
    QString    osCautionText()  const { return m_data.osInstall.cautionText; }
    QString    osWarningText()  const { return m_data.osInstall.warningText; }

    SubsystemModel* subsystemModel()  { return m_subsystemModel; }
    PciDeviceModel* pciModel()        { return m_pciModel; }
    WorkStepModel*  workStepModel()       { return m_workStepModel; }
    int             currentWorkStepIndex() const { return m_currentWorkStepIndex; }
    int             workStepCount() const { return m_workStepModel->rowCount(); }

    QVariantList recommendationBlocks() const { return m_recommendationBlocks; }
    QString recommendationsText() const;

    bool    pciIdsLoaded()       const { return m_pciAnalyzer.isPciIdsLoaded(); }
    QString pciStatusMessage()   const;

    // ── Property setters ─────────────────────────────────────────────────────
    void setDevicePageTitle(const QString& v);
    void setDeviceModel(const QString& v);
    void setDeviceSerial(const QString& v);
    void setDeviceMotherboard(const QString& v);
    void setDeviceBios(const QString& v);
    void setDeviceProcessor(const QString& v);
    void setDeviceChipset(const QString& v);
    void setDeviceRam(const QString& v);

    void setOsTestResult(const QString& v);
    void setOsTestNote(const QString& v);
    void setOsHintText(const QString& v);
    void setOsCautionText(const QString& v);
    void setOsWarningText(const QString& v);

    void setRecommendationBlocks(const QVariantList& blocks);
    void setRecommendationsText(const QString& v);
    void setCurrentWorkStepIndex(int index);

signals:
    void currentFilePathChanged();
    void isModifiedChanged();
    void windowTitleChanged();
    void deviceChanged();
    void osInstallChanged();
    void recommendationBlocksChanged();
    void recommendationsTextChanged();
    void currentWorkStepIndexChanged();
    void workStepCountChanged();
    void pciStatusChanged();
    void pciAssigned(int subsystemIndex);
    void errorOccurred(const QString& message);
    void reportLoaded();

private:
    void setModified(bool v);
    void loadReportDataIntoModels(const ReportData& data);
    ReportData collectReportDataFromModels() const;
    void loadWorkProgress(const WorkProgressData& progress, int currentIndex);
    ProgressData collectProgressData() const;
    void resetWorkProgress();
    void resetReportToDefaults();
    static QString resolveProjectReportPath(const QString& selectedPath);

    ReportData       m_data;
    QString          m_currentFilePath;
    int              m_currentWorkStepIndex = 0;
    bool             m_modified = false;

    SubsystemModel*  m_subsystemModel;
    PciDeviceModel*  m_pciModel;
    WorkStepModel*   m_workStepModel;
    WorkStepsCatalog m_workStepsCatalog;

    PciAnalyzer      m_pciAnalyzer;
    PresetManager    m_presets;
    ExamplesManager  m_examples;
    QVariantList     m_recommendationBlocks;
    QTimer           m_autoSaveTimer;
};
