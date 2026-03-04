# Report Assistant

Десктопное Linux-приложение для интерактивной сборки отчётов о программно-аппаратной совместимости с ЗОСРВ «Нейтрино» (QNX).

## Требования

- Qt 6.4+
- CMake 3.20+
- C++17 совместимый компилятор (GCC 11+ / Clang 14+)

## Сборка

```bash
# Установка зависимостей (Ubuntu/Debian)
sudo apt install qt6-base-dev qt6-declarative-dev qt6-quickcontrols2-dev cmake build-essential

# Клонирование и сборка
git clone <repo>
cd report-assistant

# Скачать pci.ids (необходим для работы PCI анализатора)
curl -o resources/pci.ids https://pci-ids.ucw.cz/v2.2/pci.ids

# Сборка
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build -j$(nproc)

# Запуск
./build/ReportAssistant
```

## Разработка через SSH

1. Открыть Cursor IDE → Remote SSH → подключиться к Linux машине
2. Открыть папку проекта
3. Редактировать файлы локально, сборка и запуск на Linux
4. Debug: `gdb ./build/ReportAssistant` или через Cursor debugger

## Структура проекта

```
src/
  core/          — C++ логика (ReportEngine, ReportParser, PciAnalyzer, ...)
  ui/            — QML интерфейс
resources/
  pci.ids        — база PCI устройств (скачать отдельно)
  presets/       — пресеты подсистем, драйверов, интерфейсов
```

## Формат файла отчёта

Приложение открывает и сохраняет `.txt` файлы в формате кастомной верстки.
Файл прогресса сохраняется рядом как `имя_отчёта.progress.json`.

## pci.ids

База данных PCI устройств не входит в репозиторий (слишком большая).
Скачайте вручную:
```bash
curl -o resources/pci.ids https://pci-ids.ucw.cz/v2.2/pci.ids
```
Или приложение использует системный файл `/usr/share/misc/pci.ids` если он установлен.
