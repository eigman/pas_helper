#include "ReportEngine.h"
#include <QTextStream>

QString ReportEngine::generate(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    // ── Header ──────────────────────────────────────────────────────────────
    s << "@page \"pas\" " << data.device.pageTitle
      << " (заводской номер " << data.device.serialNumber << ")\n\n";
    s << "@brief \n\n";
    s << "Отчет о проверке программно-аппаратной совместимости с OS_NAME ред. OS_VERSION.\n\n";
    s << "@par Содержание отчета:\n\n";
    s << "@@item Характеристика оборудования\n";
    s << "@@item Отчет о проверках\n";
    s << "@@item Детализация отчета\n";
    s << "@@item Рекомендации\n\n";

    s << generateDeviceGroup(data);
    s << generateReportGroup(data);
    s << generateTestsGroup(data);
    s << generateRecommendationsGroup(data);

    return out;
}

QString ReportEngine::generateDeviceGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "\n@group device\n\n";

    // Device parameters table (fixed 7 rows + header)
    s << "@table[width:40:60:width]\n";
    s << "@tr Технические параметры устройства @| Детализация\n";
    s << "@tr Модель                           @| " << data.device.model << "\n";
    s << "@tr Серийный/Заводской номер         @| " << data.device.serialNumber << "\n";
    s << "@tr Материнская плата                @| " << data.device.motherboard << "\n";
    s << "@tr Тип BIOS (версия)                @| " << data.device.bios << "\n";
    s << "@tr Процессор                        @| " << data.device.processor << "\n";
    s << "@tr Чипсет                           @| " << data.device.chipset << "\n";
    s << "@tr ОЗУ                              @| " << data.device.ram << "\n";
    s << "@endtable\n\n";

    // Subsystems table (dynamic rows)
    s << "@table[width:21:45:15:19:width]\n";
    s << "@tr Подсистема @| Контроллер @| Интерфейс(ы) @| Драйвер\n";
    for (const auto& sub : data.subsystems) {
        const QString ctrl = sub.controller.isEmpty() ? QStringLiteral("-") : sub.controller;
        s << "@tr " << sub.name
          << " @| " << ctrl
          << " @| " << sub.interfaces
          << " @| " << sub.driver << "\n";
    }
    s << "@endtable\n\n";

    s << "@latexonly \\newpage @endlatexonly\n\n\n\n";

    return out;
}

QString ReportEngine::generateReportGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "@group report\n\n";
    s << "@table[width:28:22:50:width]\n";
    s << "@tr Подсистема @| Результат проверки @| Примечание\n";

    // OS install — always first
    const QString osNote = data.osInstall.testNote.isEmpty()
                               ? QStringLiteral("-")
                               : data.osInstall.testNote;
    s << "@tr Установка и запуск ОС @| " << data.osInstall.testResult
      << " @| " << osNote << "\n";

    // Subsystems
    for (const auto& sub : data.subsystems) {
        const QString note = sub.testNote.isEmpty() ? QStringLiteral("-") : sub.testNote;
        s << "@tr " << sub.plainName()
          << " @| " << sub.testResult
          << " @| " << note << "\n";
    }
    s << "@endtable\n\n\n";

    return out;
}

QString ReportEngine::generateTestsGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "@group tests\n\n";
    s << "@dl\n";

    // OS install term (always first)
    s << termBlock(QStringLiteral("Установка и запуск ОС"),
                   data.osInstall.checkItems,
                   data.osInstall.testResult,
                   data.osInstall.hintText,
                   data.osInstall.cautionText);

    // Subsystem terms
    for (const auto& sub : data.subsystems) {
        s << termBlock(sub.plainName(),
                       sub.checkItems,
                       sub.testResult,
                       sub.hintText,
                       sub.cautionText);
    }

    s << "@enddl\n        \n\n";

    return out;
}

QString ReportEngine::generateRecommendationsGroup(const ReportData& data)
{
    QString out;
    QTextStream s(&out);

    s << "@group recomendations\n\n";
    if (!data.recommendations.isEmpty()) {
        s << data.recommendations;
        if (!data.recommendations.endsWith(QLatin1Char('\n'))) {
            s << "\n";
        }
    }

    return out;
}

QString ReportEngine::termBlock(const QString& termName,
                                const QList<CheckItem>& checks,
                                const QString& result,
                                const QString& hintText,
                                const QString& cautionText)
{
    QString out;
    QTextStream s(&out);

    s << "@term " << termName << "\n";
    s << "@use Перечень проверок:\n";
    s << "    @ul\n";
    for (const auto& item : checks) {
        s << "    @item " << item.text << "\n";
    }
    s << "    @endul\n";
    s << "    Результат проверки: " << result << "\n";

    if (!hintText.isEmpty()) {
        s << "    @hint\n";
        s << "    " << hintText << "\n";
        s << "    @endhint\n";
    }
    if (!cautionText.isEmpty()) {
        s << "    @caution\n";
        s << "    " << cautionText << "\n";
        s << "    @endcaution\n";
    }

    s << "\n";
    return out;
}
