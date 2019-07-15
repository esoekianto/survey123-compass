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
import QtQuick.Controls 1.4

import ArcGIS.AppFramework 1.0

TextField {
    id: textField

    property bool actionEnabled: false
    property bool actionIfReadOnly: false
    property string actionImage: "images/clear.png"
    property bool actionVisible: text > "" && (!readOnly || actionIfReadOnly)
    property bool altTextColor: false

    property int layoutDirection: xform.languageDirection

    //--------------------------------------------------------------------------

    signal action()

    //--------------------------------------------------------------------------

    style: XFormTextFieldStyle {
        style: xform.style
        altTextColor: textField.altTextColor
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (actionVisible) {
            actionButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    onLengthChanged: {
        if (actionEnabled && length > 0 && (!readOnly || actionIfReadOnly)) {
            actionButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    onLayoutDirectionChanged: {
        actionButtonLoader.anchors.left = undefined;
        actionButtonLoader.anchors.right = undefined;

        if (layoutDirection == Qt.RightToLeft) {
            actionButtonLoader.anchors.left = actionButtonLoader.parent.left;
        } else {
            actionButtonLoader.anchors.right = actionButtonLoader.parent.right;
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: actionButtonLoader

        property real actionButtonMargin: actionButtonLoader.width + actionButtonLoader.anchors.margins * 1.5
        property real endMargin: textField.__contentHeight / 3

        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            margins: 2 * AppFramework.displayScaleFactor
        }

        visible: actionVisible
        width: height
        active: false

        sourceComponent: XFormImageButton {
            source: actionImage
            color: "transparent"

            onClicked: {
                action();
            }
        }

        onVisibleChanged: {
            rebindMargins();
        }

        onLoaded: {
            rebindMargins();
        }

        function rebindMargins() {
            // console.log("rebindMargins:", parent.__panel)
            if (parent.__panel) {
                parent.__panel.rightMargin = Qt.binding(function() { return visible && layoutDirection == Qt.LeftToRight ? actionButtonMargin : endMargin; });
                parent.__panel.leftMargin = Qt.binding(function() { return visible && layoutDirection == Qt.RightToLeft ? actionButtonMargin : endMargin; });
            }
        }
    }

    //--------------------------------------------------------------------------
}
