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
import QtQuick.Controls 2.2

import ArcGIS.AppFramework 1.0

GroupBox {
    id: control

    property bool flat
    property color backgroundColor: flat ? "transparent" : "#0a000000"
    property alias border: backgroundRectangle.border

    //--------------------------------------------------------------------------

    anchors {
        leftMargin: 4 * AppFramework.displayScaleFactor
    }

    padding: 12 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    background: Rectangle {
        id: backgroundRectangle

        y: control.topPadding - control.padding
        width: parent.width
        height: parent.height - control.topPadding + control.padding

        color: control.backgroundColor
        radius: 2 * AppFramework.displayScaleFactor
    }

    //--------------------------------------------------------------------------
}
