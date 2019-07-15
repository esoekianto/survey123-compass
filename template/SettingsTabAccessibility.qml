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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

import "../Controls"

SettingsTab {

    title: qsTr("Accessibility")
    description: qsTr("Configure accessibility settings")
    icon: "images/accessibility.png"

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(AppFramework.resolvedPathUrl(appSettings.settings.path));
    }

    //--------------------------------------------------------------------------

    Item {
        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            AppSwitch {
                id: boldTextSwitch
                Layout.fillWidth: true

                checked: appSettings.boldText
                text: qsTr("Bold text")

                onCheckedChanged: {
                    appSettings.boldText = checked;
                }
            }

            AppSwitch {
                id: plainBackgroundsSwitch

                Layout.fillWidth: true

                checked: appSettings.plainBackgrounds
                text: qsTr("Plain backgrounds")

                onCheckedChanged: {
                    appSettings.plainBackgrounds = checked;
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    //--------------------------------------------------------------------------
}
