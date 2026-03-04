#pragma once

#include <QHash>
#include <QString>
#include <QList>

// Represents one parsed PCI device from a `pci -vvv` dump
struct PciDevice {
    QString vendorId;   // lowercase hex, e.g. "8086"
    QString deviceId;   // lowercase hex, e.g. "7a62"
    QString vendorName; // e.g. "Intel Corporation"
    QString deviceName; // e.g. "Raptor Lake SATA AHCI Controller" (from pci.ids lookup)
    QString classStr;   // e.g. "Mass Storage (Serial ATA)"

    // Auto-suggested subsystem name based on class (may be empty if class is unknown/internal)
    QString suggestedSubsystem;

    // Pre-formatted controller string for insertion into report:
    // "<deviceName> \n[**<vendorId>:<deviceId>**]"
    QString controllerString() const;
};

// Parses QNX `pci -vvv` output and performs pci.ids lookups.
class PciAnalyzer {
public:
    explicit PciAnalyzer();

    // Load pci.ids database from file. Searches in order:
    //   1. <binaryDir>/resources/pci.ids
    //   2. /usr/share/misc/pci.ids
    //   3. ~/.config/report-assistant/pci.ids
    // Returns true if loaded successfully.
    bool loadPciIds(const QString& binaryDir = QString());

    // Parse a full `pci -vvv` dump text.
    // Returns list of recognized (interesting) devices.
    QList<PciDevice> parseDump(const QString& dumpText) const;

    // Lookup a device name from pci.ids.
    // Returns empty string if not found.
    QString lookupDevice(const QString& vendorId, const QString& deviceId) const;
    QString lookupVendor(const QString& vendorId) const;

    bool isPciIdsLoaded() const { return m_pciIdsLoaded; }

private:
    // Suggests a subsystem name from the class string
    static QString suggestSubsystem(const QString& classStr);

    // pci.ids data: vendor_id → { vendor_name, { device_id → device_name } }
    struct VendorEntry {
        QString name;
        QHash<QString, QString> devices;
    };
    QHash<QString, VendorEntry> m_vendors;
    bool m_pciIdsLoaded = false;
};
