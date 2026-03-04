#include "PciAnalyzer.h"
#include <QFile>
#include <QTextStream>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QDir>

QString PciDevice::controllerString() const
{
    const QString name = deviceName.isEmpty()
                             ? QStringLiteral("Unknown [%1:%2]").arg(vendorId, deviceId)
                             : deviceName;
    return name + QStringLiteral(" \\n[**") + vendorId + QLatin1Char(':') + deviceId + QStringLiteral("**]");
}

PciAnalyzer::PciAnalyzer() = default;

bool PciAnalyzer::loadPciIds(const QString& binaryDir)
{
    QStringList candidates;
    if (!binaryDir.isEmpty())
        candidates << QDir(binaryDir).filePath(QStringLiteral("resources/pci.ids"));
    candidates << QStringLiteral("/usr/share/misc/pci.ids");
    candidates << QStringLiteral("/usr/share/hwdata/pci.ids");
    const QString configDir = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    candidates << QDir(configDir).filePath(QStringLiteral("pci.ids"));

    for (const QString& path : candidates) {
        QFile file(path);
        if (!file.exists()) continue;
        if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) continue;

        QTextStream in(&file);
        in.setEncoding(QStringConverter::Utf8);

        QString currentVendorId;
        VendorEntry currentVendor;

        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith(QLatin1Char('#')) || line.trimmed().isEmpty()) continue;

            if (line.startsWith(QLatin1Char('\t'))) {
                // Device line: "\tXXXX  Device Name"
                if (line.startsWith(QLatin1String("\t\t"))) continue; // subsystem, skip
                QString deviceLine = line.mid(1); // remove leading tab
                const int spaceIdx = deviceLine.indexOf(QLatin1String("  "));
                if (spaceIdx < 0) continue;
                const QString did  = deviceLine.left(spaceIdx).toLower().trimmed();
                const QString name = deviceLine.mid(spaceIdx + 2).trimmed();
                if (!currentVendorId.isEmpty())
                    m_vendors[currentVendorId].devices[did] = name;
            } else {
                // Vendor line: "XXXX  Vendor Name"
                // Save previous vendor
                if (!currentVendorId.isEmpty())
                    m_vendors[currentVendorId] = currentVendor;

                const int spaceIdx = line.indexOf(QLatin1String("  "));
                if (spaceIdx < 0) { currentVendorId.clear(); continue; }
                currentVendorId = line.left(spaceIdx).toLower().trimmed();
                currentVendor.name = line.mid(spaceIdx + 2).trimmed();
                currentVendor.devices.clear();
            }
        }
        // Save last vendor
        if (!currentVendorId.isEmpty())
            m_vendors[currentVendorId] = currentVendor;

        m_pciIdsLoaded = !m_vendors.isEmpty();
        return m_pciIdsLoaded;
    }

    return false;
}

QList<PciDevice> PciAnalyzer::parseDump(const QString& dumpText) const
{
    QList<PciDevice> result;

    // Split into individual device blocks by blank line separation.
    // Each block starts with "Class          = ..."
    const QStringList allLines = dumpText.split(QLatin1Char('\n'));

    PciDevice current;
    bool inBlock = false;

    auto tryCommit = [&]() {
        if (!current.vendorId.isEmpty() && !current.deviceId.isEmpty()) {
            // Lookup device name if not already known
            if (current.deviceName.isEmpty() || current.deviceName == QLatin1String("Unknown Unknown")) {
                current.deviceName = lookupDevice(current.vendorId, current.deviceId);
            }
            if (current.vendorName.isEmpty())
                current.vendorName = lookupVendor(current.vendorId);

            current.suggestedSubsystem = suggestSubsystem(current.classStr);
            result << current;
        }
        current = PciDevice{};
        inBlock = false;
    };

    // Regex patterns for the QNX pci -vvv output
    static const QRegularExpression reClass(QStringLiteral("^Class\\s+=\\s+(.+)$"));
    static const QRegularExpression reVendor(QStringLiteral("^Vendor ID\\s+=\\s+([0-9a-fA-F]+)h,\\s*(.*)$"));
    static const QRegularExpression reDevice(QStringLiteral("^Device ID\\s+=\\s+([0-9a-fA-F]+)h,\\s*(.*)$"));

    for (const QString& rawLine : allLines) {
        const QString line = rawLine.trimmed();

        auto mClass = reClass.match(line);
        if (mClass.hasMatch()) {
            if (inBlock) tryCommit();
            current.classStr = mClass.captured(1).trimmed();
            inBlock = true;
            continue;
        }

        if (!inBlock) continue;

        auto mVendor = reVendor.match(line);
        if (mVendor.hasMatch()) {
            current.vendorId   = mVendor.captured(1).toLower();
            current.vendorName = mVendor.captured(2).trimmed();
            continue;
        }

        auto mDevice = reDevice.match(line);
        if (mDevice.hasMatch()) {
            current.deviceId   = mDevice.captured(1).toLower();
            // Name from dump may be "Unknown Unknown" — we'll look it up
            const QString rawName = mDevice.captured(2).trimmed();
            if (rawName != QLatin1String("Unknown Unknown") &&
                !rawName.trimmed().isEmpty())
            {
                current.deviceName = rawName;
            }
            continue;
        }
    }
    if (inBlock) tryCommit();

    // Filter out internal/uninteresting devices (bridges, memory controllers, etc.)
    QList<PciDevice> filtered;
    for (const auto& dev : result) {
        if (!dev.suggestedSubsystem.isEmpty()) {
            filtered << dev;
        }
    }

    // If the user explicitly wants all devices (unfiltered), return result
    // For now return filtered list (only devices with a known subsystem mapping)
    return filtered.isEmpty() ? result : filtered;
}

QString PciAnalyzer::lookupDevice(const QString& vendorId, const QString& deviceId) const
{
    const QString vid = vendorId.toLower();
    const QString did = deviceId.toLower();
    auto vit = m_vendors.find(vid);
    if (vit == m_vendors.end()) return QString();
    auto dit = vit->devices.find(did);
    if (dit == vit->devices.end()) return QString();
    return *dit;
}

QString PciAnalyzer::lookupVendor(const QString& vendorId) const
{
    auto it = m_vendors.find(vendorId.toLower());
    if (it == m_vendors.end()) return QString();
    return it->name;
}

QString PciAnalyzer::suggestSubsystem(const QString& classStr)
{
    const QString c = classStr.toLower();

    if (c.contains(QLatin1String("display")) || c.contains(QLatin1String("vga")))
        return QStringLiteral("Графическая \\n подсистема");

    if (c.contains(QLatin1String("serial ata")) || c.contains(QLatin1String("mass storage")))
        return QStringLiteral("Дисковая \\n подсистема");

    if (c.contains(QLatin1String("ethernet")) || c.contains(QLatin1String("network")))
        return QStringLiteral("Сетевая подсистема");

    if (c.contains(QLatin1String("universal serial bus")) || c.contains(QLatin1String("usb")))
        return QStringLiteral("USB интерфейсы");

    if (c.contains(QLatin1String("audio")) || c.contains(QLatin1String("multimedia")))
        return QStringLiteral("Аудио подсистема");

    if (c.contains(QLatin1String("uart")) || c.contains(QLatin1String("serial io")))
        return QStringLiteral("Последовательные порты");

    // Skip bridges, memory controllers, signal processing — not shown in report
    return QString();
}
