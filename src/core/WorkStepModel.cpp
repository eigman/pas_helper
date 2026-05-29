#include "WorkStepModel.h"

WorkStepModel::WorkStepModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int WorkStepModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_catalog.size();
}

QVariant WorkStepModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_catalog.size())
        return {};

    const WorkStepTemplate& step = m_catalog.at(index.row());
    const WorkStepState& state = index.row() < m_states.size()
        ? m_states.at(index.row())
        : WorkStepState{};

    switch (role) {
    case StepIdRole:       return step.id;
    case TitleRole:        return step.title;
    case OverviewTagRole:  return step.overviewTag;
    case InstructionRole:  return step.instruction;
    case StatusRole:       return state.status;
    case NoteRole:         return state.note;
    case TagRole:          return state.tag;
    case StatusColorRole:  return statusColor(state.status);
    case HasStatusRole:    return !state.status.isEmpty();
    default:               return {};
    }
}

bool WorkStepModel::setData(const QModelIndex& index, const QVariant& value, int role)
{
    if (!index.isValid() || index.row() >= m_catalog.size())
        return false;

    ensureStatesSize();
    WorkStepState& state = m_states[index.row()];

    switch (role) {
    case StatusRole: state.status = value.toString(); break;
    case NoteRole:   state.note   = value.toString(); break;
    case TagRole:    state.tag    = value.toString(); break;
    default:         return false;
    }

    emitRowChanged(index.row());
    return true;
}

QHash<int, QByteArray> WorkStepModel::roleNames() const
{
    return {
        { StepIdRole,      "stepId" },
        { TitleRole,       "title" },
        { OverviewTagRole, "overviewTag" },
        { InstructionRole, "instruction" },
        { StatusRole,      "status" },
        { NoteRole,        "note" },
        { TagRole,         "tag" },
        { StatusColorRole, "statusColor" },
        { HasStatusRole,   "hasStatus" },
    };
}

void WorkStepModel::setCatalog(const QList<WorkStepTemplate>& catalog)
{
    beginResetModel();
    m_catalog = catalog;
    resetStates();
    endResetModel();
    emit countChanged();
}

void WorkStepModel::resetStates()
{
    m_states.clear();
    m_states.resize(m_catalog.size());
    emit stepDataChanged();
}

void WorkStepModel::applyProgress(const WorkProgressData& progress)
{
    beginResetModel();
    m_states.clear();
    m_states.resize(m_catalog.size());
    for (int i = 0; i < m_catalog.size() && i < progress.states.size(); ++i)
        m_states[i] = progress.states.at(i);
    endResetModel();
    emit countChanged();
    emit stepDataChanged();
}

WorkProgressData WorkStepModel::progressData() const
{
    WorkProgressData data;
    data.states = m_states;
    if (data.states.size() < m_catalog.size())
        data.states.resize(m_catalog.size());
    return data;
}

void WorkStepModel::setStatus(int index, const QString& status)
{
    setData(this->index(index, 0), status, StatusRole);
}

void WorkStepModel::setNote(int index, const QString& note)
{
    setData(this->index(index, 0), note, NoteRole);
}

void WorkStepModel::setTag(int index, const QString& tag)
{
    setData(this->index(index, 0), tag, TagRole);
}

QString WorkStepModel::statusAt(int index) const
{
    if (index < 0 || index >= m_states.size()) return {};
    return m_states.at(index).status;
}

QString WorkStepModel::instructionAt(int index) const
{
    if (index < 0 || index >= m_catalog.size()) return {};
    return m_catalog.at(index).instruction;
}

QString WorkStepModel::titleAt(int index) const
{
    if (index < 0 || index >= m_catalog.size()) return {};
    return m_catalog.at(index).title;
}

QString WorkStepModel::noteAt(int index) const
{
    if (index < 0 || index >= m_states.size()) return {};
    return m_states.at(index).note;
}

QString WorkStepModel::tagAt(int index) const
{
    if (index < 0 || index >= m_states.size()) return {};
    return m_states.at(index).tag;
}

QString WorkStepModel::statusColor(const QString& status)
{
    if (status == QLatin1String("Успешно"))           return QStringLiteral("#16A34A");
    if (status == QLatin1String("Условно успешно"))   return QStringLiteral("#D97706");
    if (status == QLatin1String("Неуспешно"))         return QStringLiteral("#DC2626");
    return QStringLiteral("#D1D5DB");
}

void WorkStepModel::ensureStatesSize()
{
    if (m_states.size() < m_catalog.size())
        m_states.resize(m_catalog.size());
}

void WorkStepModel::emitRowChanged(int index)
{
    const QModelIndex idx = this->index(index, 0);
    const QList<int> roles = {
        StatusRole, StatusColorRole, HasStatusRole,
        NoteRole, TagRole
    };
    emit dataChanged(idx, idx, roles);
    emit stepDataChanged();
}
