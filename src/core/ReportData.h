#pragma once

#include <QString>
#include <QList>

// A single check item in the "Перечень проверок" list
struct CheckItem {
    QString text;
};

// One subsystem row (appears in all 3 main tables in the report)
struct SubsystemEntry {
    // Name as shown in @group device table — may contain literal \n for line breaks
    // e.g., "Дисковая \n подсистема"
    QString name;

    // Controller string, e.g., "Raptor Lake SATA AHCI Controller \n[**8086:7a62**]"
    // Use "-" when no controller
    QString controller;

    // Interface(s), e.g., "Serial ATA" or "1x HDMI \n 1x VGA \n 1x DP"
    QString interfaces;

    // Driver, e.g., "devb-ahci" or "deva-ctrl-intel_hda.so \n deva-mixer-hda.so"
    QString driver;

    // @group report fields
    QString testResult { QStringLiteral("успешно") };
    QString testNote;

    // @group tests fields
    QList<CheckItem> checkItems;
    QString hintText;    // content of @hint block (empty = no hint)
    QString cautionText; // content of @caution block (empty = no caution)

    // Returns name with \n stripped and collapsed to a space
    // Used in @group report table and @term blocks
    QString plainName() const {
        QString plain = name;
        plain.replace(QStringLiteral(" \\n "), QStringLiteral(" "));
        plain.replace(QStringLiteral("\\n"), QStringLiteral(" "));
        return plain.trimmed();
    }
};

// The "Установка и запуск ОС" entry — always first in report/tests, never in device table
struct OsInstallEntry {
    QString testResult { QStringLiteral("успешно") };
    QString testNote;
    QList<CheckItem> checkItems;
    QString hintText;
    QString cautionText;
};

// Device hardware parameters (first table in @group device)
struct DeviceParams {
    QString pageTitle;    // Title line after @page "pas", e.g., "ПК KVADRA TAU"
    QString model;        // Модель
    QString serialNumber; // Серийный/Заводской номер
    QString motherboard;  // Материнская плата
    QString bios;         // Тип BIOS (версия)
    QString processor;    // Процессор
    QString chipset;      // Чипсет
    QString ram;          // ОЗУ
};

// Complete report document state
struct ReportData {
    DeviceParams device;
    OsInstallEntry osInstall;
    QList<SubsystemEntry> subsystems;
    QString recommendations; // content of @group recomendations

    bool isEmpty() const {
        return device.pageTitle.isEmpty() && subsystems.isEmpty();
    }
};
