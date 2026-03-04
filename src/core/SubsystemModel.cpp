#include "SubsystemModel.h"

SubsystemModel::SubsystemModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int SubsystemModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_data.size();
}

QVariant SubsystemModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const SubsystemEntry& e = m_data.at(index.row());

    switch (role) {
    case NameRole:        return e.name;
    case ControllerRole:  return e.controller;
    case InterfacesRole:  return e.interfaces;
    case DriverRole:      return e.driver;
    case TestResultRole:  return e.testResult;
    case TestNoteRole:    return e.testNote;
    case CheckItemsRole: {
        QStringList items;
        for (const auto& ci : e.checkItems) items << ci.text;
        return items;
    }
    case HintTextRole:    return e.hintText;
    case CautionTextRole: return e.cautionText;
    case IsCompleteRole:  return !e.name.isEmpty() && !e.driver.isEmpty();
    default: return {};
    }
}

bool SubsystemModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid() || index.row() >= m_data.size()) return false;
    SubsystemEntry& e = m_data[index.row()];

    switch (role) {
    case NameRole:        e.name        = value.toString(); break;
    case ControllerRole:  e.controller  = value.toString(); break;
    case InterfacesRole:  e.interfaces  = value.toString(); break;
    case DriverRole:      e.driver      = value.toString(); break;
    case TestResultRole:  e.testResult  = value.toString(); break;
    case TestNoteRole:    e.testNote    = value.toString(); break;
    case HintTextRole:    e.hintText    = value.toString(); break;
    case CautionTextRole: e.cautionText = value.toString(); break;
    default: return false;
    }

    emit dataChanged(index, index, { role, IsCompleteRole });
    return true;
}

QHash<int, QByteArray> SubsystemModel::roleNames() const
{
    return {
        { NameRole,        "name"        },
        { ControllerRole,  "controller"  },
        { InterfacesRole,  "interfaces"  },
        { DriverRole,      "driver"      },
        { TestResultRole,  "testResult"  },
        { TestNoteRole,    "testNote"    },
        { CheckItemsRole,  "checkItems"  },
        { HintTextRole,    "hintText"    },
        { CautionTextRole, "cautionText" },
        { IsCompleteRole,  "isComplete"  },
    };
}

void SubsystemModel::setSubsystems(const QList<SubsystemEntry>& subsystems)
{
    beginResetModel();
    m_data = subsystems;
    endResetModel();
    emit countChanged();
}

void SubsystemModel::addSubsystem(const QString& name)
{
    SubsystemEntry e;
    e.name = name;
    e.testResult = QStringLiteral("успешно");
    beginInsertRows({}, m_data.size(), m_data.size());
    m_data << e;
    endInsertRows();
    emit countChanged();
}

void SubsystemModel::removeSubsystem(int index)
{
    if (index < 0 || index >= m_data.size()) return;
    beginRemoveRows({}, index, index);
    m_data.removeAt(index);
    endRemoveRows();
    emit countChanged();
}

void SubsystemModel::moveSubsystem(int from, int to)
{
    if (from == to || from < 0 || to < 0 ||
        from >= m_data.size() || to >= m_data.size()) return;

    beginMoveRows({}, from, from, {}, to > from ? to + 1 : to);
    m_data.move(from, to);
    endMoveRows();
}

void SubsystemModel::setField(int index, const QString& field, const QVariant& value)
{
    if (index < 0 || index >= m_data.size()) return;
    SubsystemEntry& e = m_data[index];
    bool changed = false;

    if (field == QLatin1String("name"))        { e.name        = value.toString(); changed = true; }
    else if (field == QLatin1String("controller"))  { e.controller  = value.toString(); changed = true; }
    else if (field == QLatin1String("interfaces"))  { e.interfaces  = value.toString(); changed = true; }
    else if (field == QLatin1String("driver"))      { e.driver      = value.toString(); changed = true; }
    else if (field == QLatin1String("testResult"))  { e.testResult  = value.toString(); changed = true; }
    else if (field == QLatin1String("testNote"))    { e.testNote    = value.toString(); changed = true; }
    else if (field == QLatin1String("hintText"))    { e.hintText    = value.toString(); changed = true; }
    else if (field == QLatin1String("cautionText")) { e.cautionText = value.toString(); changed = true; }

    if (changed) notifyRow(index);
}

void SubsystemModel::setCheckItems(int index, const QStringList& items)
{
    if (index < 0 || index >= m_data.size()) return;
    m_data[index].checkItems.clear();
    for (const QString& t : items)
        m_data[index].checkItems << CheckItem{ t };
    notifyRow(index);
}

void SubsystemModel::addCheckItem(int index, const QString& text)
{
    if (index < 0 || index >= m_data.size()) return;
    m_data[index].checkItems << CheckItem{ text };
    notifyRow(index);
}

void SubsystemModel::removeCheckItem(int subsystemIndex, int checkIndex)
{
    if (subsystemIndex < 0 || subsystemIndex >= m_data.size()) return;
    auto& checks = m_data[subsystemIndex].checkItems;
    if (checkIndex < 0 || checkIndex >= checks.size()) return;
    checks.removeAt(checkIndex);
    notifyRow(subsystemIndex);
}

QVariantMap SubsystemModel::getSubsystem(int index) const
{
    if (index < 0 || index >= m_data.size()) return {};
    const SubsystemEntry& e = m_data.at(index);

    QStringList checkItems;
    for (const auto& ci : e.checkItems) checkItems << ci.text;

    return {
        { QStringLiteral("name"),        e.name        },
        { QStringLiteral("controller"),  e.controller  },
        { QStringLiteral("interfaces"),  e.interfaces  },
        { QStringLiteral("driver"),      e.driver      },
        { QStringLiteral("testResult"),  e.testResult  },
        { QStringLiteral("testNote"),    e.testNote    },
        { QStringLiteral("checkItems"),  checkItems    },
        { QStringLiteral("hintText"),    e.hintText    },
        { QStringLiteral("cautionText"), e.cautionText },
    };
}

void SubsystemModel::notifyRow(int row)
{
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx);
}
