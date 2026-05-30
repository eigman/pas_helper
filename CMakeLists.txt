cmake_minimum_required(VERSION 3.16)
project(ReportAssistant VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Qt 6.2+ is required (Ubuntu 22.04 ships Qt 6.2.4)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick QuickControls2 Qml)

set(SOURCES
    src/main.cpp
    src/core/AppController.cpp
    src/core/ReportEngine.cpp
    src/core/ReportParser.cpp
    src/core/PciAnalyzer.cpp
    src/core/PresetManager.cpp
    src/core/ExamplesManager.cpp
    src/core/RecommendationsConverter.cpp
    src/core/Storage.cpp
    src/core/SubsystemModel.cpp
    src/core/PciDeviceModel.cpp
    src/core/WorkStepsCatalog.cpp
    src/core/WorkStepModel.cpp
    src/core/WorkSummaryExporter.cpp
)

qt_add_executable(ReportAssistant ${SOURCES})
# Avoid conflict: linker outputs exe to bin/; POST_BUILD copies resources to bin/resources/
set_target_properties(ReportAssistant PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

set_source_files_properties(src/ui/main.qml              PROPERTIES QT_RESOURCE_ALIAS main.qml)
set_source_files_properties(src/ui/WorkTab.qml            PROPERTIES QT_RESOURCE_ALIAS WorkTab.qml)
set_source_files_properties(src/ui/ReportTab.qml          PROPERTIES QT_RESOURCE_ALIAS ReportTab.qml)
set_source_files_properties(src/ui/components/DeviceForm.qml            PROPERTIES QT_RESOURCE_ALIAS DeviceForm.qml)
set_source_files_properties(src/ui/components/SubsystemDetail.qml       PROPERTIES QT_RESOURCE_ALIAS SubsystemDetail.qml)
set_source_files_properties(src/ui/components/PciPanel.qml              PROPERTIES QT_RESOURCE_ALIAS PciPanel.qml)
set_source_files_properties(src/ui/components/RecommendationsEditor.qml PROPERTIES QT_RESOURCE_ALIAS RecommendationsEditor.qml)
set_source_files_properties(src/ui/components/SidebarNavItem.qml        PROPERTIES QT_RESOURCE_ALIAS SidebarNavItem.qml)
set_source_files_properties(src/ui/components/SidebarSubsystemItem.qml  PROPERTIES QT_RESOURCE_ALIAS SidebarSubsystemItem.qml)
set_source_files_properties(src/ui/components/DeviceFieldCard.qml        PROPERTIES QT_RESOURCE_ALIAS DeviceFieldCard.qml)
set_source_files_properties(src/ui/components/ResultToggle.qml           PROPERTIES QT_RESOURCE_ALIAS ResultToggle.qml)
set_source_files_properties(src/ui/components/PresetsPopup.qml           PROPERTIES QT_RESOURCE_ALIAS PresetsPopup.qml)
set_source_files_properties(src/ui/components/PresetPickerPopup.qml      PROPERTIES QT_RESOURCE_ALIAS PresetPickerPopup.qml)
set_source_files_properties(src/ui/components/InterfacePickerPopup.qml   PROPERTIES QT_RESOURCE_ALIAS InterfacePickerPopup.qml)
set_source_files_properties(src/ui/components/RamPickerPopup.qml         PROPERTIES QT_RESOURCE_ALIAS RamPickerPopup.qml)
set_source_files_properties(src/ui/components/FieldHelpIcon.qml           PROPERTIES QT_RESOURCE_ALIAS FieldHelpIcon.qml)
set_source_files_properties(src/ui/components/FieldLabelRow.qml          PROPERTIES QT_RESOURCE_ALIAS FieldLabelRow.qml)
set_source_files_properties(src/ui/components/InstructionView.qml        PROPERTIES QT_RESOURCE_ALIAS InstructionView.qml)
set_source_files_properties(src/ui/components/WorkStepListItem.qml      PROPERTIES QT_RESOURCE_ALIAS WorkStepListItem.qml)
set_source_files_properties(src/ui/components/WorkNavButton.qml         PROPERTIES QT_RESOURCE_ALIAS WorkNavButton.qml)

qt_add_qml_module(ReportAssistant
    URI ReportAssistant
    VERSION 1.0
    QML_FILES
        src/ui/main.qml
        src/ui/WorkTab.qml
        src/ui/ReportTab.qml
        src/ui/components/DeviceForm.qml
        src/ui/components/SubsystemDetail.qml
        src/ui/components/PciPanel.qml
        src/ui/components/RecommendationsEditor.qml
        src/ui/components/SidebarNavItem.qml
        src/ui/components/SidebarSubsystemItem.qml
        src/ui/components/DeviceFieldCard.qml
        src/ui/components/ResultToggle.qml
        src/ui/components/PresetsPopup.qml
        src/ui/components/PresetPickerPopup.qml
        src/ui/components/InterfacePickerPopup.qml
        src/ui/components/RamPickerPopup.qml
        src/ui/components/FieldHelpIcon.qml
        src/ui/components/FieldLabelRow.qml
        src/ui/components/InstructionView.qml
        src/ui/components/WorkStepListItem.qml
        src/ui/components/WorkNavButton.qml
    )

# Resources (presets JSON + icons) embedded via Qt resource system
qt_add_resources(ReportAssistant "appresources"
    PREFIX "/"
    FILES
        resources/presets/subsystems.json
        resources/presets/field_examples.json
        resources/presets/work_steps.json
        resources/icons/disk.svg
        resources/icons/monitor.svg
        resources/icons/network.svg
        resources/icons/usb.svg
        resources/icons/keyboard.svg
        resources/icons/audio.svg
        resources/icons/serial.svg
        resources/icons/wifi.svg
        resources/icons/settings.svg
        resources/icons/pci.svg
        resources/icons/recommendations.svg
        resources/icons/remark-hint.svg
        resources/icons/remark-caution.svg
        resources/icons/remark-error.svg
        resources/icons/app-icon.png
)

target_link_libraries(ReportAssistant PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Qml
)

# Copy resources to build dir so pci.ids and presets are accessible at runtime
add_custom_command(TARGET ReportAssistant POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${CMAKE_SOURCE_DIR}/resources
        $<TARGET_FILE_DIR:ReportAssistant>/resources
    COMMENT "Copying resources to build directory"
)

install(TARGETS ReportAssistant RUNTIME DESTINATION bin)
install(DIRECTORY resources/ DESTINATION share/report-assistant/resources)
