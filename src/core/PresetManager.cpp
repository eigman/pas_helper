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
        const QJsonArray checks = obj.value(QLatin1String("defaultChecks")).toArray();
        for (const QJsonValue& c : checks)
            preset.defaultChecks << c.toString();
        m_subsystems << preset;
    }

    // Load flat lists
    auto toStringList = [](const QJsonArray& arr) {
        QStringList list;
        for (const QJsonValue& v : arr) list << v.toString();
        return list;
    };

    m_drivers        = toStringList(root.value(QLatin1String("drivers")).toArray());
    m_interfaces     = toStringList(root.value(QLatin1String("interfaces")).toArray());
    m_osInstallChecks = toStringList(root.value(QLatin1String("osInstallChecks")).toArray());

    return true;
}

QStringList PresetManager::subsystemNames() const
{
    QStringList names;
    for (const auto& p : m_subsystems) names << p.name;
    return names;
}

QStringList PresetManager::drivers() const { return m_drivers; }
QStringList PresetManager::interfaces() const { return m_interfaces; }
QStringList PresetManager::osInstallChecks() const { return m_osInstallChecks; }

QStringList PresetManager::checksForSubsystem(const QString& subsystemName) const
{
    const QString target = subsystemName.toLower().trimmed();
    for (const auto& p : m_subsystems) {
        if (p.name.toLower().trimmed() == target)
            return p.defaultChecks;
        // Also match plain name (without \n)
        QString plain = p.name;
        plain.replace(QStringLiteral(" \\n "), QStringLiteral(" "));
        plain.replace(QStringLiteral("\\n"), QStringLiteral(" "));
        if (plain.toLower().trimmed() == target)
            return p.defaultChecks;
    }
    return {};
}
