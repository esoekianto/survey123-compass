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

import "../Controls"

StyledTextField {
    id: textField

    signal cleared(string oldValue);

    //--------------------------------------------------------------------------

    fontFamily: app.fontFamily

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        clearButtonLoader.active = true;

        if (Qt.platform.os === "android") {
            inputMethodHints |= Qt.ImhNoPredictiveText;
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: clearButtonLoader

        property real clearButtonMargin: clearButtonLoader.width + clearButtonLoader.anchors.margins * 1.5
        property int textDirection: Qt.locale().textDirection
        property real endMargin: textField.__contentHeight / 3

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 2 * AppFramework.displayScaleFactor
        }

        visible: parent.text > "" && !parent.readOnly
        width: height
        active: false

        sourceComponent: StyledImageButton {
            source: "images/clear.png"

            onClicked: {
                clear();
            }
        }

        onTextDirectionChanged: {
            anchors.left = undefined;
            anchors.right = undefined;

            if (textDirection == Qt.RightToLeft) {
                anchors.left = parent.left;
            } else {
                anchors.right = parent.right;
            }
        }

        onLoaded: {
            rebindMargins();
        }

        onVisibleChanged: {
            rebindMargins();
        }

        function rebindMargins() {
            // console.log("rebindMargins:", parent.__panel)
            if (parent.__panel) {
                parent.__panel.rightMargin = Qt.binding(function() { return visible && textDirection == Qt.LeftToRight ? clearButtonMargin : endMargin; });
                parent.__panel.leftMargin = Qt.binding(function() { return visible && textDirection == Qt.RightToLeft ? clearButtonMargin : endMargin; });
            }
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        var oldValue = text;
        text = "";
        cleared(oldValue);
        editingFinished();
    }

    //--------------------------------------------------------------------------
}
