#pragma once

#include <QString>
#include <QStringList>
#include <QList>
#include <QJsonObject>

struct SubsystemPreset {
    QString name;
    QString icon; // icon key, e.g. "disk", "monitor", "network"
    QStringList defaultChecks;
    QString defaultController;
    QString defaultInterfaces;
    QString defaultDriver;
};

// Loads preset data (subsystem names, fieldPresets per icon, default checks).
// drivers()/interfaces() — объединение всех fieldPresets (fallback для пустой иконки).
// from resources/presets/subsystems.json.
class PresetManager {
public:
    bool load(const QString& presetsFilePath);

    QStringList subsystemNames() const;
    QString iconForSubsystem(const QString& subsystemName) const;
    QStringList drivers() const;
    QStringList interfaces() const;
    QStringList driversForIcon(const QString& icon) const;
    QStringList interfacesForIcon(const QString& icon) const;
    QStringList osInstallChecks() const;
    QStringList defaultOsInstallChecks() const;
    QStringList checksForSubsystem(const QString& subsystemName) const;
    SubsystemPreset presetForSubsystem(const QString& subsystemName) const;

    const QList<SubsystemPreset>& subsystemPresets() const { return m_subsystems; }

private:
    QStringList listForIcon(const QJsonObject& byIcon, const QString& icon,
                            const QStringList& fallback) const;

    QList<SubsystemPreset> m_subsystems;
    QStringList m_drivers;
    QStringList m_interfaces;
    QStringList m_osInstallChecks;
    QStringList m_defaultOsInstallChecks;
    QJsonObject m_driversByIcon;
    QJsonObject m_interfacesByIcon;
};
