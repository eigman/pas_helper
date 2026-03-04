#pragma once

#include "ReportData.h"
#include <QAbstractListModel>

// Qt list model exposing the subsystems list to QML.
// Roles map directly to SubsystemEntry fields.
class SubsystemModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        ControllerRole,
        InterfacesRole,
        DriverRole,
        TestResultRole,
        TestNoteRole,
        CheckItemsRole,   // QStringList
        HintTextRole,
        CautionTextRole,
        IsCompleteRole,   // bool: name + controller + driver all filled
    };
    Q_ENUM(Roles)

    explicit SubsystemModel(QObject* parent = nullptr);

    // QAbstractListModel interface
    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    // Bulk replace (used when loading a report)
    void setSubsystems(const QList<SubsystemEntry>& subsystems);
    QList<SubsystemEntry> subsystems() const { return m_data; }

    Q_INVOKABLE void addSubsystem(const QString& name);
    Q_INVOKABLE void removeSubsystem(int index);
    Q_INVOKABLE void moveSubsystem(int from, int to);

    // Field setters for the currently selected subsystem (called from detail panel)
    Q_INVOKABLE void setField(int index, const QString& field, const QVariant& value);

    // Returns all fields of a subsystem as a QVariantMap for QML access.
    // Keys: "name", "controller", "interfaces", "driver", "testResult",
    //       "testNote", "checkItems" (QStringList), "hintText", "cautionText"
    Q_INVOKABLE QVariantMap getSubsystem(int index) const;

    // Check items CRUD
    Q_INVOKABLE void setCheckItems(int index, const QStringList& items);
    Q_INVOKABLE void addCheckItem(int index, const QString& text);
    Q_INVOKABLE void removeCheckItem(int subsystemIndex, int checkIndex);

signals:
    void countChanged();

private:
    QList<SubsystemEntry> m_data;

    void notifyRow(int row);
};
