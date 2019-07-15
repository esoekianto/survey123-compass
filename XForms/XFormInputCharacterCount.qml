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

import ArcGIS.AppFramework 1.0

Loader {
    property Item control: parent
    property real warningThreshold: 0.75
    property bool remaining: true
    property bool overThreshold: control.length / control.maximumLength > warningThreshold

    //--------------------------------------------------------------------------

    visible: control.activeFocus && !control.readOnly && control.enabled && enabled
    active: visible

    //--------------------------------------------------------------------------

    Text {
        anchors {
            right: parent.right
            top: parent.top
        }

        text: remaining
              ? control.maximumLength - control.length
              : "%1/%2".arg(control.length).arg(control.maximumLength)

        color: overThreshold
               ? xform.style.inputCountWarningColor
               : xform.style.inputCountColor

        font {
            family: xform.style.fontFamily
            pixelSize: 11 * AppFramework.displayScaleFactor
            bold: overThreshold
        }

        horizontalAlignment: Text.AlignRight

        MouseArea {
            anchors.fill: parent

            onClicked: {
                remaining = !remaining;
            }
        }
    }

    //--------------------------------------------------------------------------
}
