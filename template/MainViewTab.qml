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
import QtGraphicalEffects 1.0

Rectangle {
    //--------------------------------------------------------------------------

    property string title
    property string shortTitle: title
    property url iconSource
    property Component indicator: defaultIndicator
    readonly property bool isCurrentTab: SwipeView.isCurrentItem
    property AppMenu menu

    //--------------------------------------------------------------------------

    signal indicatorPressAndHold()

    //--------------------------------------------------------------------------

    color: app.backgroundColor

    //--------------------------------------------------------------------------

    Component {
        id: defaultIndicator

        Item {
            property color currentColor

            Image {
                id: image

                anchors.fill: parent
                source: iconSource
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                verticalAlignment: Image.AlignVCenter
                visible: false
            }

            ColorOverlay {
                anchors.fill: image

                source: image
                color: currentColor
            }
        }
    }

    //--------------------------------------------------------------------------
}
