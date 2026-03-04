#include "PciDeviceModel.h"

PciDeviceModel::PciDeviceModel(QObject* parent)
    : QAbstractListModel(parent)
{}

int PciDeviceModel::rowCount(const QModelIndex& parent) const
{
    if (parent.isValid()) return 0;
    return m_data.size();
}

QVariant PciDeviceModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_data.size()) return {};
    const PciDevice& d = m_data.at(index.row());

    switch (role) {
    case VendorIdRole:            return d.vendorId;
    case DeviceIdRole:            return d.deviceId;
    case VendorNameRole:          return d.vendorName;
    case DeviceNameRole:          return d.deviceName;
    case ClassStrRole:            return d.classStr;
    case SuggestedSubsystemRole:  return d.suggestedSubsystem;
    case ControllerStringRole:    return d.controllerString();
    default: return {};
    }
}

QHash<int, QByteArray> PciDeviceModel::roleNames() const
{
    return {
        { VendorIdRole,           "vendorId"           },
        { DeviceIdRole,           "deviceId"           },
        { VendorNameRole,         "vendorName"         },
        { DeviceNameRole,         "deviceName"         },
        { ClassStrRole,           "classStr"           },
        { SuggestedSubsystemRole, "suggestedSubsystem" },
        { ControllerStringRole,   "controllerString"   },
    };
}

void PciDeviceModel::setDevices(const QList<PciDevice>& devices)
{
    beginResetModel();
    m_data = devices;
    endResetModel();
    emit countChanged();
}

PciDevice PciDeviceModel::deviceAt(int index) const
{
    if (index < 0 || index >= m_data.size()) return {};
    return m_data.at(index);
}
