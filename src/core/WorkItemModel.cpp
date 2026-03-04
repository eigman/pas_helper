#include "WorkItemModel.h"

WorkItemModel::WorkItemModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int WorkItemModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_data.size();
}

QVariant WorkItemModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const WorkItem& item = m_data.at(index.row());
    switch (role) {
    case TextRole: return item.text;
    case DoneRole: return item.done;
    default: return {};
    }
}

bool WorkItemModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid() || index.row() >= m_data.size()) return false;
    WorkItem& item = m_data[index.row()];
    switch (role) {
    case TextRole: item.text = value.toString(); break;
    case DoneRole: item.done = value.toBool();   break;
    default: return false;
    }
    emit dataChanged(index, index, { role });
    return true;
}

QHash<int, QByteArray> WorkItemModel::roleNames() const
{
    return { { TextRole, "itemText" }, { DoneRole, "done" } };
}

void WorkItemModel::addItem(const QString& text)
{
    beginInsertRows({}, m_data.size(), m_data.size());
    m_data << WorkItem{ text, false };
    endInsertRows();
    emit countChanged();
}

void WorkItemModel::removeItem(int index)
{
    if (index < 0 || index >= m_data.size()) return;
    beginRemoveRows({}, index, index);
    m_data.removeAt(index);
    endRemoveRows();
    emit countChanged();
}

void WorkItemModel::setDone(int index, bool done)
{
    if (index < 0 || index >= m_data.size()) return;
    m_data[index].done = done;
    const QModelIndex idx = this->index(index);
    emit dataChanged(idx, idx, { DoneRole });
}

void WorkItemModel::setText(int index, const QString& text)
{
    if (index < 0 || index >= m_data.size()) return;
    m_data[index].text = text;
    const QModelIndex idx = this->index(index);
    emit dataChanged(idx, idx, { TextRole });
}

void WorkItemModel::setItems(const QList<WorkItem>& items)
{
    beginResetModel();
    m_data = items;
    endResetModel();
    emit countChanged();
}
