cmake_minimum_required(VERSION 3.20)
project(ReportAssistant VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Qml)

qt_standard_project_setup(REQUIRES 6.4)

set(SOURCES
    src/main.cpp
    src/core/AppController.cpp
    src/core/ReportEngine.cpp
    src/core/ReportParser.cpp
    src/core/PciAnalyzer.cpp
    src/core/PresetManager.cpp
    src/core/Storage.cpp
    src/core/SubsystemModel.cpp
    src/core/PciDeviceModel.cpp
    src/core/WorkItemModel.cpp
)

qt_add_executable(ReportAssistant ${SOURCES})

qt_add_qml_module(ReportAssistant
    URI ReportAssistant
    VERSION 1.0
    QML_FILES
        src/ui/main.qml
        src/ui/WorkTab.qml
        src/ui/ReportTab.qml
        src/ui/components/DeviceForm.qml
        src/ui/components/SubsystemsPage.qml
        src/ui/components/SubsystemDetail.qml
        src/ui/components/PciPanel.qml
        src/ui/components/RecommendationsEditor.qml
    RESOURCES
        resources/presets/subsystems.json
)

# pci.ids is loaded at runtime from disk, not embedded as Qt resource
# Download it: curl -o resources/pci.ids https://pci-ids.ucw.cz/v2.2/pci.ids
# At runtime the app looks for it at:
#   1. ./resources/pci.ids (relative to binary, for development)
#   2. /usr/share/misc/pci.ids (system)
#   3. ~/.config/report-assistant/pci.ids (user override)

target_link_libraries(ReportAssistant PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
)

# Copy resources to build dir for development
add_custom_command(TARGET ReportAssistant POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/resources
        $<TARGET_FILE_DIR:ReportAssistant>/resources
    COMMENT "Copying resources to build directory"
)

install(TARGETS ReportAssistant
    RUNTIME DESTINATION bin
)
install(DIRECTORY resources/
    DESTINATION share/report-assistant/resources
)
