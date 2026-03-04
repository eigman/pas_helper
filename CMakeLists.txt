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
    src/core/Storage.cpp
    src/core/SubsystemModel.cpp
    src/core/PciDeviceModel.cpp
    src/core/WorkItemModel.cpp
)

qt_add_executable(ReportAssistant ${SOURCES})
# Avoid conflict: linker outputs exe to bin/; POST_BUILD copies resources to bin/resources/
set_target_properties(ReportAssistant PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

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
)

# Resources (presets JSON) embedded via Qt resource system
qt_add_resources(ReportAssistant "appresources"
    PREFIX "/"
    FILES
        resources/presets/subsystems.json
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
