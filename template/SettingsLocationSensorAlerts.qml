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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Notifications 1.0

SettingsLocationSensorTab {
    title: qsTr("Alerts")
    icon: "images/exclamation-mark-triangle.png" //"images/bell.png"

    property bool initialized

    //--------------------------------------------------------------------------

    Component.onCompleted: initialized = true

    //--------------------------------------------------------------------------

    Connections {
        target: appSettings

        onLocationSensorActivationModeChanged: {
            if (initialized) {
                asNeededButton.checked = appSettings.locationSensorActivationMode === appSettings.kActivationModeAsNeeded;
                inSurveyButton.checked = appSettings.locationSensorActivationMode === appSettings.kActivationModeInSurvey;
                alwaysRunningButton.checked = appSettings.locationSensorActivationMode === appSettings.kActivationModeAlways;
            }
        }

        onLocationAlertsVisualChanged: {
            if (initialized) {
                visualSwitch.checked = appSettings.locationAlertsVisual;
            }
        }

        onLocationAlertsSpeechChanged: {
            if (initialized) {
                speechSwitch.checked = appSettings.locationAlertsSpeech;
            }
        }

        onLocationAlertsVibrateChanged: {
            if (initialized) {
                vibrateSwitch.checked = appSettings.locationAlertsVibrate;
            }
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        GroupColumnLayout {
            Layout.fillWidth: true

            title: qsTr("Connection mode")

            AppRadioButton {
                id: asNeededButton

                Layout.fillWidth: true

                text: qsTr("As needed")

                checked: appSettings.locationSensorActivationMode === appSettings.kActivationModeAsNeeded

                onCheckedChanged: {
                    if (initialized && !appSettings.updating && checked) {
                        appSettings.locationSensorActivationMode = appSettings.kActivationModeAsNeeded;
                    }
                }
            }

            AppRadioButton {
                id: inSurveyButton

                Layout.fillWidth: true

                text: qsTr("When using a survey")
                checked: appSettings.locationSensorActivationMode === appSettings.kActivationModeInSurvey

                onCheckedChanged: {
                    if (initialized && !appSettings.updating && checked) {
                        appSettings.locationSensorActivationMode = appSettings.kActivationModeInSurvey;
                    }
                }
            }

            AppRadioButton {
                id: alwaysRunningButton

                Layout.fillWidth: true

                text: qsTr("Always while %1 is running").arg(app.info.title)
                checked: appSettings.locationSensorActivationMode === appSettings.kActivationModeAlways

                onCheckedChanged: {
                    if (initialized && !appSettings.updating && checked) {
                        appSettings.locationSensorActivationMode = appSettings.kActivationModeAlways;
                    }
                }
            }
        }

        GroupColumnLayout {
            Layout.fillWidth: true

            title: qsTr("Alert style")

            AppSwitch {
                id: visualSwitch

                Layout.fillWidth: true

                checked: appSettings.locationAlertsVisual

                text: qsTr("Display messages")

                onCheckedChanged: {
                    if (initialized && !appSettings.updating) {
                        appSettings.locationAlertsVisual = checked;
                    }
                }
            }

            AppSwitch {
                id: speechSwitch

                Layout.fillWidth: true

                checked: appSettings.locationAlertsSpeech

                text: qsTr("Announce with text to speech")

                onCheckedChanged: {
                    if (initialized && !appSettings.updating) {
                        appSettings.locationAlertsSpeech = checked;
                    }
                }
            }

            AppSwitch {
                id: vibrateSwitch

                Layout.fillWidth: true

                enabled: Vibration.supported
                checked: appSettings.locationAlertsVibrate

                text: qsTr("Vibrate")

                onCheckedChanged: {
                    if (initialized && !appSettings.updating) {
                        appSettings.locationAlertsVibrate = checked;
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    //--------------------------------------------------------------------------
}
