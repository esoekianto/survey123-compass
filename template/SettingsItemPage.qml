import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

Component {
    id: settingsItemPage

    Page {
        property Item settingsTab
        property AppSettings appSettings: app.appSettings

        property alias settingsComponent: loader.sourceComponent
        property alias settingsItem: loader.item

        signal loaderComplete();

        contentMargins: 0

        contentItem: Loader {
            id: loader
        }

        Component.onDestruction: {
            saveSettings();
        }

        onTitlePressAndHold: {
            settingsTab.titlePressAndHold();
        }

        //--------------------------------------------------------------------------

        function saveSettings() {
            appSettings.write();
        }

        //--------------------------------------------------------------------------
    }
}
