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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"
Item {
    id: control

    //--------------------------------------------------------------------------

    property string groupLabel
    property string minorLabel
    property string majorLabel
    property string thresholdLabel

    property ListModel minorUnitsModel
    property ListModel majorUnitsModel

    property bool collapsed: true
    property bool collapsible: true
    property int languageDirection: Qt.LeftToRight

    //--------------------------------------------------------------------------

    implicitHeight: layout.height

    //--------------------------------------------------------------------------

    ColumnLayout {
        id: layout

        anchors {
            left: parent.left
            right: parent.right
        }

        spacing: 5 * AppFramework.displayScaleFactor

        RowLayout {
            Layout.fillWidth: true

            layoutDirection: control.languageDirection

            Loader {
                Layout.preferredWidth: 25 * AppFramework.displayScaleFactor
                Layout.preferredHeight: Layout.preferredWidth

                active: collapsible
                visible: collapsible
                sourceComponent: Image {

                    fillMode: Image.PreserveAspectFit
                    source: "../XForms/images/group-indicator.png"

                    rotation: collapsed ? (languageDirection === Qt.RightToLeft ? 90 : -90) : 0

                    Behavior on rotation {
                        NumberAnimation {
                            duration: 200
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            collapsed = !collapsed;
                        }
                    }
                }
            }

            AppText {
                Layout.fillWidth: true

                text: groupLabel

                font {
                    pointSize: 16
                    bold: true
                }
            }
        }

        ColumnLayout {
            id: controls

            Layout.fillWidth: true
            Layout.leftMargin: 20 * AppFramework.displayScaleFactor

            visible: !collapsed

            spacing: 5 * AppFramework.displayScaleFactor

            RowLayout {
                Layout.fillWidth: true

                spacing: 5 * AppFramework.displayScaleFactor

                AppText {
                    Layout.preferredWidth: controls.width * 0.3

                    text: minorLabel
                }

                StyledComboBox {
                    id: minorComboBox

                    Layout.fillWidth: true

                    model: minorUnitsModel
                    textRole: "label"
                }

                StyledComboBox {
                    Layout.fillWidth: true

                    model: 10
                }
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: 5 * AppFramework.displayScaleFactor

                AppText {
                    Layout.preferredWidth: controls.width * 0.3

                    text: majorLabel
                }

                StyledComboBox {
                    Layout.fillWidth: true

                    model: majorUnitsModel
                    textRole: "label"
                }
            }

            RowLayout {
                Layout.fillWidth: true

                spacing: 5 * AppFramework.displayScaleFactor

                AppText {
                    Layout.preferredWidth: controls.width * 0.3

                    text: thresholdLabel
                }

                NumberField {
                    Layout.fillWidth: true

                    suffixText: minorComboBox.currentText
                    value: 123
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true

            height: 1 * AppFramework.displayScaleFactor
            color: "#20000000"
        }
    }

    //--------------------------------------------------------------------------
}
