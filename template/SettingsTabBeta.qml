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

    title: qsTr("Beta")
    description: qsTr("Configure beta features")
    icon: "images/beta.png"

    //--------------------------------------------------------------------------

    property AppFeatures features: app.features

    property bool restart: false

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(AppFramework.resolvedPathUrl(appSettings.settings.path));
    }

    //--------------------------------------------------------------------------

    Item {
        Component.onCompleted: {
            restart = false;
        }

        Component.onDestruction: {
            features.write();
        }

        //--------------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

            spacing: 10 * AppFramework.displayScaleFactor

            AppText {
                Layout.fillWidth: true

                visible: restart
                text: qsTr("%1 must be restarted when beta features have been enabled or disabled.").arg(app.info.title)
                color: "#a80000"

                font {
                    pointSize: 16
                    bold: true
                }

                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.addIns
                text: qsTr("Add-Ins")

                onCheckedChanged: {
                    features.addIns = checked;
                    restart = true;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.accessibility
                text: qsTr("Accessibility")

                onCheckedChanged: {
                    features.accessibility = checked;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.inlineErrorMessages
                text: qsTr("Inline error messages in forms")

                onCheckedChanged: {
                    features.inlineErrorMessages = checked;
                }
            }

            AppSwitch {
                Layout.fillWidth: true

                checked: features.listCache
                text: qsTr("Cache lists")

                onCheckedChanged: {
                    features.listCache = checked;
                    restart = true;
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
