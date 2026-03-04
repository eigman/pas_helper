#pragma once

#include <QAbstractListModel>
#include <QList>

struct WorkItem {
    QString text;
    bool done = false;
};

// Simple checklist model for the Work tab.
class WorkItemModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        TextRole = Qt::UserRole + 1,
        DoneRole,
    };

    explicit WorkItemModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    bool setData(const QModelIndex& index, const QVariant& value, int role = Qt::EditRole) override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addItem(const QString& text);
    Q_INVOKABLE void removeItem(int index);
    Q_INVOKABLE void setDone(int index, bool done);
    Q_INVOKABLE void setText(int index, const QString& text);

    QList<WorkItem> items() const { return m_data; }
    void setItems(const QList<WorkItem>& items);

signals:
    void countChanged();

private:
    QList<WorkItem> m_data;
};
