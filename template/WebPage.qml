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
import ArcGIS.AppFramework.WebView 1.0

Page {
    id: page

    //--------------------------------------------------------------------------

    property url url

    //--------------------------------------------------------------------------

    backButton {
        visible: mainStackView.depth > 1
    }

    //--------------------------------------------------------------------------

    actionButton {
        visible: false
    }

    //--------------------------------------------------------------------------

    contentMargins: 0
    contentItem: Rectangle {
        anchors.fill: parent

        color: "white"

        BrowserView {
            anchors.fill: parent
            visible: true

            url: page.url

//            onUrlChanged: {
//                console.log("WebPage url:", url);
//            }

            onVisibleChanged: {
                if (!visible) {
                    closePage();
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}

