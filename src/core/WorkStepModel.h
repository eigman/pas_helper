#pragma once

#include "WorkStepTypes.h"
#include <QAbstractListModel>
#include <QList>

class WorkStepModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        StepIdRole = Qt::UserRole + 1,
        TitleRole,
        OverviewTagRole,
        InstructionRole,
        StatusRole,
        NoteRole,
        TagRole,
        StatusColorRole,
        HasStatusRole,
    };

    explicit WorkStepModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    void setCatalog(const QList<WorkStepTemplate>& catalog);
    void resetStates();
    void applyProgress(const WorkProgressData& progress);
    WorkProgressData progressData() const;

    Q_INVOKABLE void setStatus(int index, const QString& status);
    Q_INVOKABLE void setNote(int index, const QString& note);
    Q_INVOKABLE void setTag(int index, const QString& tag);
    Q_INVOKABLE QString statusAt(int index) const;
    Q_INVOKABLE QString instructionAt(int index) const;
    Q_INVOKABLE QString titleAt(int index) const;
    Q_INVOKABLE QString noteAt(int index) const;
    Q_INVOKABLE QString tagAt(int index) const;

    static QString statusColor(const QString& status);

signals:
    void countChanged();
    void stepDataChanged();

private:
    void ensureStatesSize();
    void emitRowChanged(int index);

    QList<WorkStepTemplate> m_catalog;
    QList<WorkStepState>    m_states;
};
