/* Copyright 2019 Esri
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
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

SettingsTab {

    title: qsTr("Units")
    description: qsTr("Configure measurement units")
    icon: "images/units.png"

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        Qt.openUrlExternally(AppFramework.resolvedPathUrl(appSettings.settings.path));
    }

    //--------------------------------------------------------------------------

    ScrollView {
        id: scrollView

        clip: true

        ColumnLayout {
            id: layout

            x: 10 * AppFramework.displayScaleFactor
            width: scrollView.width - 20 * AppFramework.displayScaleFactor

            spacing: 10 * AppFramework.displayScaleFactor

            UnitsGroup {
                Layout.fillWidth: true

                groupLabel: qsTr("Length")
                minorLabel: qsTr("Short lengths")
                majorLabel: qsTr("Long lengths")
                thresholdLabel: qsTr("Short to long lengths threshold")

                minorUnitsModel: unitsModel
                majorUnitsModel: unitsModel

                collapsed: false
            }

            UnitsGroup {
                Layout.fillWidth: true

                groupLabel: qsTr("Area")

                minorLabel: qsTr("Small areas")
                majorLabel: qsTr("Large areas")
                thresholdLabel: qsTr("Small to large area threshold")

                minorUnitsModel: unitsModel
                majorUnitsModel: unitsModel

                collapsed: false
            }

            UnitsGroup {
                Layout.fillWidth: true

                groupLabel: qsTr("Height")

                minorLabel: qsTr("Low heights")
                majorLabel: qsTr("High heights")
                thresholdLabel: qsTr("Low to high heights threshold")

                minorUnitsModel: unitsModel
                majorUnitsModel: unitsModel
            }

            UnitsGroup {
                Layout.fillWidth: true

                groupLabel: qsTr("Speed")

                minorLabel: qsTr("Slow speeds")
                majorLabel: qsTr("Fast speeds")
                thresholdLabel: qsTr("Slow to fast speeds threshold")

                minorUnitsModel: unitsModel
                majorUnitsModel: unitsModel
            }
        }

        //--------------------------------------------------------------------------

        ListModel {
            id: unitsModel

            ListElement {
                value: 1
                label: "A"
            }

            ListElement {
                value: 2
                label: "B"
            }

            ListElement {
                value: 3
                label: "C"
            }
        }

    }

    //--------------------------------------------------------------------------
}
