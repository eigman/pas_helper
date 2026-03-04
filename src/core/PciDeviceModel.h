#pragma once

#include "PciAnalyzer.h"
#include <QAbstractListModel>

// Exposes the list of parsed PCI devices to QML (for the PCI panel table).
class PciDeviceModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        VendorIdRole = Qt::UserRole + 1,
        DeviceIdRole,
        VendorNameRole,
        DeviceNameRole,
        ClassStrRole,
        SuggestedSubsystemRole,
        ControllerStringRole,
    };

    explicit PciDeviceModel(QObject* parent = nullptr);

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void setDevices(const QList<PciDevice>& devices);
    PciDevice deviceAt(int index) const;

signals:
    void countChanged();

private:
    QList<PciDevice> m_data;
};
