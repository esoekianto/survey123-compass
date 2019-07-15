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

Rectangle {
    id: dropdownField

    property bool dropdownVisible: false
    property alias text: valueText.text
    property alias textField: valueText
    property int count: 1
    property int originalCount: 1
    property alias altTextColor: valueText.altTextColor
    property bool valid: true

    //--------------------------------------------------------------------------

    signal cleared()
    signal keyPressed()

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }
    
    border {
        color: valueText.activeFocus
               ? xform.style.inputActiveBorderColor
               : xform.style.inputBorderColor
    }
    
    height: valueLayout.height + border.width * 2
    radius: height * 0.16
    color: xform.style.inputBackgroundColor

    //--------------------------------------------------------------------------

    RowLayout {
        id: valueLayout
        
        anchors {
            left: parent.left
            right: parent.right
            margins: padding
            verticalCenter: parent.verticalCenter
        }

        layoutDirection: xform.languageDirection

        Image {
            Layout.preferredWidth: valueLayout.height
            Layout.preferredHeight: Layout.preferredWidth

            source: "images/search.png"
            fillMode: Image.PreserveAspectFit
            visible: dropdownField.enabled && valueText.activeFocus
        }

        XFormTextField {
            id: valueText
            
            Layout.fillWidth: true
            
            enabled: originalCount > 0
            actionEnabled: true

            style: XFormTextFieldStyle {
                style: xform.style
                altTextColor: valueText.altTextColor

                background: Item {
                    anchors.fill: parent
                }

                font {
                    italic: !dropdownField.valid
                }
            }

            onAction: {
                text = "";
                cleared();
            }

            Keys.onPressed: {
                keyPressed();
            }
        }

        Loader {
            Layout.preferredHeight: 15 * xform.style.textScaleFactor * AppFramework.displayScaleFactor
            Layout.preferredWidth: Layout.preferredHeight

            sourceComponent: dropdownImageComponent
        }
    }

    Component {
        id: dropdownImageComponent
        Image {
            visible: originalCount > 0
            source: dropdownVisible ? "images/arrow-up.png" : "images/arrow-down.png"
            fillMode: Image.PreserveAspectFit
            
            MouseArea {
                anchors.fill: parent

                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: originalCount > 0

                onClicked: {
                    dropdownVisible = !dropdownVisible;
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
