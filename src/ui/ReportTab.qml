import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

// Report tab — contains sub-tabs: Device params | Subsystems | Recommendations
Item {
    id: root

    // Bubbled up signals — connected in main.qml
    signal openPciRequested()
    signal saveAsRequested()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Sub-tab bar
        TabBar {
            id: reportTabBar
            Layout.fillWidth: true
            Material.accent: Material.Teal

            TabButton {
                text: "Параметры устройства"
                icon.name: "computer"
            }
            TabButton {
                text: "Подсистемы"
                icon.name: "settings"
            }
            TabButton {
                text: "Рекомендации"
                icon.name: "description"
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: reportTabBar.currentIndex

            // Page 1: Device parameters
            DeviceForm {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            // Page 2: Subsystems master-detail
            SubsystemsPage {
                Layout.fillWidth: true
                Layout.fillHeight: true
                onOpenPciRequested: root.openPciRequested()
            }

            // Page 3: Recommendations
            RecommendationsEditor {
                Layout.fillWidth: true
                Layout.fillHeight: true
                onSaveAsRequested: root.saveAsRequested()
            }
        }
    }
}
