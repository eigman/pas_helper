#pragma once

#include <QString>
#include <QStringList>
#include <QJsonObject>

// Loads field placeholders and hover examples from resources/presets/field_examples.json.
class ExamplesManager {
public:
    bool load(const QString& filePath);

    QString placeholder(const QString& scope, const QString& fieldKey,
                        const QString& contextKey = {}) const;
    QStringList examples(const QString& scope, const QString& fieldKey,
                         const QString& contextKey = {}) const;

private:
    QJsonObject fieldEntry(const QString& scope, const QString& fieldKey,
                           const QString& contextKey) const;

    QJsonObject m_root;
};
