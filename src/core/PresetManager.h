#pragma once

#include <QString>
#include <QStringList>
#include <QList>

struct SubsystemPreset {
    QString name;
    QStringList defaultChecks;
};

// Loads preset data (subsystem names, drivers, interfaces, default checks)
// from resources/presets/subsystems.json.
class PresetManager {
public:
    bool load(const QString& presetsFilePath);

    QStringList subsystemNames() const;
    QStringList drivers() const;
    QStringList interfaces() const;
    QStringList osInstallChecks() const;
    QStringList checksForSubsystem(const QString& subsystemName) const;

    const QList<SubsystemPreset>& subsystemPresets() const { return m_subsystems; }

private:
    QList<SubsystemPreset> m_subsystems;
    QStringList m_drivers;
    QStringList m_interfaces;
    QStringList m_osInstallChecks;
};
