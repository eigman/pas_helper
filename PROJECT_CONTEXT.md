# Report Assistant — Project Context

## What Is This

Desktop Linux application for assembling hardware-software compatibility reports (отчёты о программно-аппаратной совместимости) for QNX-based OS (ЗОСРВ «Нейтрино»). The app lets you:

1. Fill in device parameters and subsystem details interactively
2. Analyze PCI bus output (`pci -vvv`) and map devices to subsystems
3. Export a `.txt` file in the custom markup format used by a Jenkins report generator
4. Open and edit existing `.txt` report files
5. Track work progress with a separate checklist (Work tab)

## Report Format (Custom Markup)

The output `.txt` file uses a custom markup language. **Any missing closing tag breaks PDF generation.**

### Structure (4 groups, mandatory order):

```
@page "pas" <Device Title> (заводской номер <SerialN>)
@brief

Отчет о проверке программно-аппаратной совместимости с OS_NAME ред. OS_VERSION.

@par Содержание отчета:

@@item Характеристика оборудования
@@item Отчет о проверках
@@item Детализация отчета
@@item Рекомендации


@group device

@table[width:40:60:width]
@tr Технические параметры устройства @| Детализация
@tr Модель                           @| <model>
@tr Серийный/Заводской номер         @| <serial>
@tr Материнская плата                @| <motherboard>
@tr Тип BIOS (версия)                @| <bios>
@tr Процессор                        @| <cpu>
@tr Чипсет                           @| <chipset>
@tr ОЗУ                              @| <ram>
@endtable

@table[width:21:45:15:19:width]
@tr Подсистема @| Контроллер @| Интерфейс(ы) @| Драйвер
@tr <subName> @| <controller> \n[**vid:did**] @| <interfaces> @| <driver>
...
@endtable

@latexonly \newpage @endlatexonly



@group report

@table[width:28:22:50:width]
@tr Подсистема @| Результат проверки @| Примечание
@tr Установка и запуск ОС @| успешно @| <note>
@tr <subPlainName> @| <result> @| <note>
...
@endtable


@group tests

@dl
@term Установка и запуск ОС
@use Перечень проверок:
    @ul
    @item <check>
    @endul
    Результат проверки: успешно
    @hint
    <hint text>
    @endhint

@term <subPlainName>
@use Перечень проверок:
    @ul
    @item <check>
    @endul
    Результат проверки: <result>
    @caution
    <caution text>
    @endcaution

@enddl
        

@group recomendations

<free text with @ul/@ol blocks>
```

### Key Rules:
- `OS_NAME` and `OS_VERSION` are **static tags** — never replaced by app, substituted by Jenkins
- `\n` inside a cell = line break in PDF (literal `\` + `n`, not actual newline)
- Subsystem name in device table: may use `\n` (e.g., `Дисковая \n подсистема`)
- Subsystem name in report table and `@term`: plain name, `\n` stripped
- Controller format: `<Name from pci.ids> \n[**vendorid:deviceid**]` (IDs in lowercase hex)

## PCI Dump Format (QNX `pci -vvv`)

Input example:
```
Class          = Mass Storage (Serial ATA)
Vendor ID      = 8086h, Intel Corporation
Device ID      = 7a62h, Unknown Unknown
```

Parsing logic:
- Extract VID: `8086h` → `8086` (strip `h`)
- Extract DID: `7a62h` → `7a62`
- Look up name in `resources/pci.ids` (standard pci.ids format)
- Map Class code to suggested subsystem

## Class → Subsystem Mapping
```
Display (VGA)               → Графическая \n подсистема
Mass Storage (Serial ATA)   → Дисковая \n подсистема
Network (Ethernet)          → Сетевая подсистема
Serial Bus (Universal Serial Bus) → USB интерфейсы
Multimedia (Audio)          → Аудио подсистема
Communication (Other/UART)  → Последовательные порты
```

## File Layout
```
report-assistant/
├── CMakeLists.txt
├── PROJECT_CONTEXT.md
├── .cursor/rules/
│   ├── project-context.mdc  (alwaysApply:true)
│   ├── cpp-standards.mdc    (globs: src/**/*.{h,cpp})
│   └── qml-standards.mdc   (globs: src/ui/**/*.qml)
├── src/
│   ├── main.cpp
│   ├── core/
│   │   ├── ReportData.h          plain structs
│   │   ├── AppController.h/cpp   main QML bridge
│   │   ├── ReportEngine.h/cpp    TXT generator
│   │   ├── ReportParser.h/cpp    TXT → form
│   │   ├── PciAnalyzer.h/cpp     PCI dump parser
│   │   ├── PresetManager.h/cpp   JSON presets
│   │   ├── Storage.h/cpp         file I/O
│   │   ├── SubsystemModel.h/cpp  QAbstractListModel
│   │   ├── PciDeviceModel.h/cpp  QAbstractListModel
│   │   └── WorkItemModel.h/cpp   QAbstractListModel
│   └── ui/
│       ├── main.qml
│       ├── WorkTab.qml
│       ├── ReportTab.qml
│       └── components/
│           ├── DeviceForm.qml
│           ├── SubsystemsPage.qml
│           ├── SubsystemDetail.qml
│           ├── PciPanel.qml
│           └── RecommendationsEditor.qml
└── resources/
    ├── pci.ids            (download from https://pci-ids.ucw.cz/v2.2/pci.ids)
    └── presets/
        └── subsystems.json
```

## Progress Save Format (`filename.progress.json`)
```json
{
  "version": 1,
  "reportData": { ... serialized ReportData ... },
  "workNotes": "...",
  "workItems": [{"text": "...", "done": false}]
}
```

## Roadmap
- [x] Project structure + Cursor rules
- [ ] Core data structures + CMake
- [ ] ReportEngine (TXT generation)
- [ ] ReportParser (TXT reading)
- [ ] PciAnalyzer
- [ ] AppController + QML UI
- [ ] Git remote + SSH debug setup
- [ ] AppImage packaging
- [ ] Jenkins API integration (future)
- [ ] Knowledge base (future)
