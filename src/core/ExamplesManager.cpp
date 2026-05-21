#include "ExamplesManager.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonArray>

namespace {
QStringList jsonToStringList(const QJsonArray& arr)
{
    QStringList list;
    for (const QJsonValue& v : arr)
        list << v.toString();
    return list;
}
} // namespace

bool ExamplesManager::load(const QString& filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject())
        return false;

    m_root = doc.object();
    return true;
}

QJsonObject ExamplesManager::fieldEntry(const QString& scope, const QString& fieldKey,
                                        const QString& contextKey) const
{
    const QJsonObject scopeObj = m_root.value(scope).toObject();
    if (scope == QLatin1String("subsystem")) {
        if (!contextKey.isEmpty()) {
            const QJsonObject byIcon = scopeObj.value(QLatin1String("byIcon")).toObject();
            const QJsonObject iconObj = byIcon.value(contextKey).toObject();
            const QJsonObject entry = iconObj.value(fieldKey).toObject();
            if (!entry.isEmpty())
                return entry;
        }
        return scopeObj.value(QLatin1String("defaults")).toObject().value(fieldKey).toObject();
    }

    return scopeObj.value(fieldKey).toObject();
}

QString ExamplesManager::placeholder(const QString& scope, const QString& fieldKey,
                                   const QString& contextKey) const
{
    return fieldEntry(scope, fieldKey, contextKey).value(QLatin1String("placeholder")).toString();
}

QStringList ExamplesManager::examples(const QString& scope, const QString& fieldKey,
                                      const QString& contextKey) const
{
    const QJsonArray arr = fieldEntry(scope, fieldKey, contextKey)
                               .value(QLatin1String("examples"))
                               .toArray();
    return jsonToStringList(arr);
}
