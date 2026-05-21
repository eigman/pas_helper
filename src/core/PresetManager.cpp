#include "PresetManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

bool PresetManager::load(const QString& presetsFilePath)
{
    QFile file(presetsFilePath);
    if (!file.open(QIODevice::ReadOnly)) return false;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return false;

    const QJsonObject root = doc.object();

    // Load subsystem presets
    m_subsystems.clear();
    const QJsonArray subsystems = root.value(QLatin1String("subsystems")).toArray();
    for (const QJsonValue& v : subsystems) {
        const QJsonObject obj = v.toObject();
        SubsystemPreset preset;
        preset.name = obj.value(QLatin1String("name")).toString();
        preset.icon = obj.value(QLatin1String("icon")).toString();
        const QJsonArray checks = obj.value(QLatin1String("defaultChecks")).toArray();
        for (const QJsonValue& c : checks)
            preset.defaultChecks << c.toString();
        preset.defaultController  = obj.value(QLatin1String("defaultController")).toString();
        preset.defaultInterfaces = obj.value(QLatin1String("defaultInterfaces")).toString();
        preset.defaultDriver      = obj.value(QLatin1String("defaultDriver")).toString();
        m_subsystems << preset;
    }

    auto toStringList = [](const QJsonArray& arr) {
        QStringList list;
        for (const QJsonValue& v : arr)
            list << v.toString().trimmed();
        return list;
    };

    auto uniqueUnionFromByIcon = [](const QJsonObject& byIcon) {
        QStringList list;
        for (auto it = byIcon.begin(); it != byIcon.end(); ++it) {
            for (const QJsonValue& v : it.value().toArray()) {
                const QString s = v.toString().trimmed();
                if (!s.isEmpty() && !list.contains(s))
                    list << s;
            }
        }
        return list;
    };

    m_osInstallChecks = toStringList(root.value(QLatin1String("osInstallChecks")).toArray());
    m_defaultOsInstallChecks = toStringList(root.value(QLatin1String("defaultOsInstallChecks")).toArray());
    if (m_defaultOsInstallChecks.isEmpty())
        m_defaultOsInstallChecks = m_osInstallChecks;

    const QJsonObject fieldPresets = root.value(QLatin1String("fieldPresets")).toObject();
    m_driversByIcon    = fieldPresets.value(QLatin1String("drivers")).toObject();
    m_interfacesByIcon = fieldPresets.value(QLatin1String("interfaces")).toObject();
    m_drivers          = uniqueUnionFromByIcon(m_driversByIcon);
    m_interfaces       = uniqueUnionFromByIcon(m_interfacesByIcon);

    return true;
}

QStringList PresetManager::listForIcon(const QJsonObject& byIcon, const QString& icon,
                                       const QStringList& fallback) const
{
    const QJsonArray arr = byIcon.value(icon).toArray();
    if (arr.isEmpty())
        return fallback;
    QStringList list;
    for (const QJsonValue& v : arr)
        list << v.toString();
    return list;
}

QStringList PresetManager::driversForIcon(const QString& icon) const
{
    return listForIcon(m_driversByIcon, icon, m_drivers);
}

QStringList PresetManager::interfacesForIcon(const QString& icon) const
{
    return listForIcon(m_interfacesByIcon, icon, m_interfaces);
}

QStringList PresetManager::subsystemNames() const
{
    QStringList names;
    for (const auto& p : m_subsystems) names << p.name;
    return names;
}

QString PresetManager::iconForSubsystem(const QString& subsystemName) const
{
    const QString target = subsystemName.toLower().trimmed();
    for (const auto& p : m_subsystems) {
        if (p.name.toLower().trimmed() == target)
            return p.icon;
        QString plain = p.name;
        plain.replace(QStringLiteral(" \\n "), QStringLiteral(" "));
        plain.replace(QStringLiteral("\\n"), QStringLiteral(" "));
        if (plain.toLower().trimmed() == target)
            return p.icon;
    }
    return QStringLiteral("settings");
}

QStringList PresetManager::drivers() const { return m_drivers; }
QStringList PresetManager::interfaces() const { return m_interfaces; }
QStringList PresetManager::osInstallChecks() const { return m_osInstallChecks; }
QStringList PresetManager::defaultOsInstallChecks() const { return m_defaultOsInstallChecks; }

SubsystemPreset PresetManager::presetForSubsystem(const QString& subsystemName) const
{
    const QString target = subsystemName.toLower().trimmed();
    for (const auto& p : m_subsystems) {
        if (p.name.toLower().trimmed() == target)
            return p;
        QString plain = p.name;
        plain.replace(QStringLiteral(" \\n "), QStringLiteral(" "));
        plain.replace(QStringLiteral("\\n"), QStringLiteral(" "));
        if (plain.toLower().trimmed() == target)
            return p;
    }
    return {};
}

QStringList PresetManager::checksForSubsystem(const QString& subsystemName) const
{
    return presetForSubsystem(subsystemName).defaultChecks;
}
