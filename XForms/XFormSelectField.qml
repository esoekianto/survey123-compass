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
    property int count: 1
    property bool valid: true
    property int changeReason

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }
    
    border {
        color: xform.style.inputBorderColor
        width: 1
    }
    
    height: valueLayout.height + padding * 2
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
        
        Text {
            id: valueText
            
            Layout.fillWidth: true
            
            color: changeReason === 3 ? xform.style.valueAltColor : xform.style.valueColor
            font {
                pointSize: xform.style.inputPointSize
                bold: xform.style.inputBold
                family: xform.style.inputFontFamily
                italic: !valid
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }
        
        Loader {
            Layout.preferredHeight: 15 * xform.style.textScaleFactor * AppFramework.displayScaleFactor
            Layout.preferredWidth: Layout.preferredHeight

            sourceComponent: dropdownImageComponent
        }
    }
    
    MouseArea {
        anchors.fill: parent

        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: count > 0
        
        onClicked: {
            dropdownVisible = !dropdownVisible;
        }
    }

    Component {
        id: dropdownImageComponent
        Image {
            visible: count > 0
            source: dropdownVisible ? "images/arrow-up.png" : "images/arrow-down.png"
            fillMode: Image.PreserveAspectFit
        }
    }

    //--------------------------------------------------------------------------
}
