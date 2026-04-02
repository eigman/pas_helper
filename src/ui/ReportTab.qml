import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ReportAssistant 1.0

// Report tab — navigation is driven by sidebar (pageIndex from main.qml)
// pageIndex: 0 = device params, 1..N = subsystem[i-1], N+1 = recommendations
Item {
    id: root

    property int pageIndex: 0
    property int subsystemIndex: -1

    signal openPciRequested()
    signal saveAsRequested()

    StackLayout {
        anchors.fill: parent
        currentIndex: {
            const subsystemCount = controller.subsystemModel.count
            if (pageIndex === 0) return 0
            if (pageIndex >= 1 && pageIndex <= subsystemCount) return 1
            return 2
        }

        // Page 0: Device parameters
        DeviceForm {}

        // Page 1..N: Subsystem detail
        SubsystemDetail {
            subsystemIndex: root.subsystemIndex
            onOpenPciRequested: root.openPciRequested()
        }

        // Page N+1: Recommendations
        RecommendationsEditor {
            onSaveAsRequested: root.saveAsRequested()
        }
    }
}
