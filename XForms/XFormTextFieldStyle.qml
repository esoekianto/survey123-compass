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
import QtQuick.Controls.Styles 1.4

import ArcGIS.AppFramework 1.0

TextFieldStyle {
    property XFormStyle style
    property bool valid: true
    property bool altTextColor

    renderType: Text.QtRendering
    
    textColor: valid &&
               control.acceptableInput
               ? altTextColor
                 ? style.inputAltTextColor
                 : (control.readOnly ? style.inputReadOnlyTextColor : style.inputTextColor)
    : style.inputErrorTextColor
    
    placeholderTextColor: style.inputPlaceholderTextColor
    
    font {
        bold: style.inputBold
        pointSize: style.inputPointSize
        family: style.inputFontFamily
    }
    
    background: Rectangle {
        id: baserect
        
        anchors.fill: parent
        
        radius: control.__contentHeight * 0.16
        
        color: control.readOnly
               ? style.inputReadOnlyBackgroundColor
               : style.inputBackgroundColor
        
        border {
            //width: control.activeFocus ? 2 * AppFramework.displayScaleFactor : 1
            color: control.activeFocus
                   ? style.inputActiveBorderColor
                   : style.inputBorderColor
        }
    }
}
