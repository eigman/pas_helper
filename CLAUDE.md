# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Configure (once)
cmake -B build -DCMAKE_BUILD_TYPE=Debug

# Build
cmake --build build -j$(nproc)

# Run
./build/bin/ReportAssistant
```

No test suite exists — verification is manual via the GUI.

## What This Is

Desktop Linux app (Qt6 + QML + C++17) for assembling hardware-software compatibility reports for QNX-based OS (ЗОСРВ «Нейтрино»). Outputs `.txt` files in a custom markup format consumed by a Jenkins-based PDF generator.

Key workflows:
1. Fill in device parameters and subsystem details
2. Paste `pci -vvv` output → auto-parse and assign PCI devices to subsystems
3. Export/open `.txt` report files
4. Track work progress via a checklist (Work tab)

## Architecture

**Entry point:** `main.cpp` creates `AppController`, exposes it to QML as `controller` context property, then loads `main.qml`.

**C++ side (`src/core/`):**
- `AppController` — central QObject bridge; owns all data and drives QML via `Q_PROPERTY` + `Q_INVOKABLE`
- `ReportData.h` — plain structs: `DeviceParams`, `SubsystemEntry`, `OsInstallEntry`, `ReportData`
- `ReportEngine` / `ReportParser` — generate and parse the custom `.txt` markup
- `PciAnalyzer` — parses QNX `pci -vvv` dump and looks up names in `resources/pci.ids`
- `PresetManager` — loads `resources/presets/subsystems.json` (subsystem names, drivers, interfaces, check items)
- `Storage` — file I/O for `.txt` reports and `.progress.json` checkpoints
- `SubsystemModel`, `PciDeviceModel`, `WorkItemModel` — `QAbstractListModel` subclasses for QML ListViews

**QML side (`src/ui/`):**
- All business logic lives in C++; QML is bindings and visual state only
- Bind to `controller.*`, call `Q_INVOKABLE` methods
- Update fields on `onEditingFinished` / `onActivated`, not `onTextChanged` (avoids feedback loops)

## Report Markup Format

The output `.txt` has four mandatory groups in fixed order. **Missing any closing tag breaks PDF generation.**

```
@page "pas" <Device Title> (заводской номер <SerialN>)
@brief ... @group device ... @group report ... @group tests ... @group recomendations
```

Key rules:
- `\n` inside a cell = literal line break in PDF (backslash + n, not a newline character)
- Subsystem name in `@group device` table may use `\n`; in `@group report` and `@term` it must be stripped
- Controller format: `<Name from pci.ids> \n[**vendorid:deviceid**]` (IDs lowercase hex)
- `OS_NAME` / `OS_VERSION` are static tags substituted by Jenkins, not by this app

## C++ Conventions

- C++17; `std::unique_ptr` / Qt parent ownership — no raw owning pointers
- `#pragma once` in all headers
- `PascalCase` classes, `camelCase` methods/variables, `m_` prefix for private members
- Signals/slots via `connect()` only — no old `SIGNAL`/`SLOT` macros
- `Q_PROPERTY` for all QML-exposed fields, always with `NOTIFY` signal
- File I/O returns `bool` success and emits `errorOccurred(QString)` on failure — no silent failures

## QML Conventions

- Qt Quick Controls 2, `Material.Dark` theme, `Material.accent: Material.Teal`
- `camelCase` for `id:` values; components in separate files under `src/ui/components/`
- `ColumnLayout`/`RowLayout`/`GridLayout` for layout; `spacing: 12` default, `topPadding/bottomPadding: 16` for content areas

## External Resources

- `resources/pci.ids` is **not in the repo** (too large). Download from `https://pci-ids.ucw.cz/v2.2/pci.ids` and place in `resources/`. Fallback lookup order at runtime: `<binaryDir>/resources/pci.ids` → `/usr/share/misc/pci.ids` → `~/.config/report-assistant/pci.ids`
- `resources/presets/subsystems.json` is embedded via Qt resource system and compiled into the binary

## Progress Save Format

Auto-saved as `<reportfile>.progress.json` alongside the `.txt` file (ignored by git):

```json
{
  "version": 1,
  "reportData": { "...serialized ReportData..." },
  "workNotes": "...",
  "workItems": [{"text": "...", "done": false}]
}
```
