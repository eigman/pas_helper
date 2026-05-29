#include "WorkStepsCatalog.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>

bool WorkStepsCatalog::load(const QString& path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly))
        return false;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject())
        return false;

    const QJsonArray arr = doc.object().value(QLatin1String("steps")).toArray();
    m_steps.clear();
    for (const QJsonValue& v : arr) {
        const QJsonObject obj = v.toObject();
        WorkStepTemplate step;
        step.id          = obj.value(QLatin1String("id")).toString();
        step.title       = obj.value(QLatin1String("title")).toString();
        step.overviewTag = obj.value(QLatin1String("overviewTag")).toString();
        step.instruction = obj.value(QLatin1String("instruction")).toString();
        if (!step.id.isEmpty() && !step.title.isEmpty())
            m_steps << step;
    }
    return !m_steps.isEmpty();
}
