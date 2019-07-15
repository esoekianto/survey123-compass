/* Copyright 2018 Esri
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

Page {
    id: page

    title: qsTr("Settings")

    //--------------------------------------------------------------------------

    property bool showBeta: false

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        showBeta = true;
    }

    //--------------------------------------------------------------------------

    contentMargins: 0
    contentItem: ListTabView {
        id: settingsPageListTabView

        delegate: settingsDelegate

        SettingsTabAccessibility {
            enabled: app.features.accessibility
        }

        SettingsTabText {
        }

        SettingsTabPortal {
        }

        /*
            SettingsTabImages {
            }
            */

        SettingsTabLocation {
        }

        SettingsTabUnits {
            enabled: showBeta || app.features.beta
        }

        SettingsTabStorage {
        }

        SettingsTabAddIns {
            enabled: app.features.addIns
            portal: app.portal
        }

        SettingsTabDiagnostics {
        }

        SettingsTabBeta {
            enabled: showBeta || app.features.beta
        }

        SettingsItemPage {
            id: settingsItemPage
        }

        onSelected: {
            page.Stack.view.push(settingsItemPage,
                                 {
                                     settingsTab: item,
                                     title: item.title,
                                     settingsComponent: item.contentComponent,
                                 });
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: settingsDelegate

        SettingsTabDelegate {
            listTabView: settingsPageListTabView
        }
    }

    //--------------------------------------------------------------------------
}
