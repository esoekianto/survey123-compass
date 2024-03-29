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
import QtQuick.Controls 2.3
import QtQuick.Controls 1.4 as Controls1

import ArcGIS.AppFramework 1.0

import "../Portal"

Item {
    id: container

    //--------------------------------------------------------------------------

    property alias path: addIn.path
    property alias addIn: addIn
    property alias loader: loader
    property alias asynchronous: loader.asynchronous
    property alias context: context
    property alias instance: loader.item
    property alias active: loader.active

    property bool showBackground: true
    property alias canClose: context.canClose

    readonly property string title: (instance && instance.title > "")
                                    ? instance.title
                                    : addIn.title

    property bool debug: true

    //--------------------------------------------------------------------------

    signal loaded()

    //--------------------------------------------------------------------------

    implicitWidth: 100
    implicitHeight: 100

    //--------------------------------------------------------------------------

    Loader {
        anchors.fill: parent

        sourceComponent: backgroundComponent
        active: showBackground && loader.status !== Loader.Ready
        asynchronous: true
    }
    
    //--------------------------------------------------------------------------

    Loader {
        id: loader
        
        anchors.fill: parent
        
        asynchronous: true

        onStatusChanged: {
            switch (status) {
            case Loader.Error:
                console.error("Error loading add-in:", JSON.stringify(addIn.addInInfo, undefined, 2));
                break;
            }
        }

        onLoaded: {
            console.log("AddInContainer loaded title:", addIn.title);

            try {
                if (typeof instance.title === "string" && instance.title.length === 0) {
                    instance.title = addIn.title;
                }
            } catch (e) {
                console.error("Failed to set empty add-in title:", e);
            }

            container.loaded();
        }
    }

    //--------------------------------------------------------------------------

    AddIn {
        id: addIn

        Component.onCompleted: {
            console.log("AddInContainer:", addIn.mainSource);
            loader.setSource(mainSource,
                             {
                                 context: context,
                                 //title: addIn.title
                             });
        }
    }

    //--------------------------------------------------------------------------

    AddInContext {
        id: context

        property bool canClose: false

        addIn: addIn
        portal: app.portal
    }

    //--------------------------------------------------------------------------

    Component {
        id: backgroundComponent

        Item {
            Image {
                anchors.fill: parent

                source: addIn.thumbnail
                fillMode: Image.PreserveAspectCrop
                opacity: 0.1
            }

            AppText {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: busyIndicator.top
                    margins: 10 * AppFramework.displayScaleFactor
                }

                text: addIn.title
                font {
                    pointSize: 20
                }
                horizontalAlignment: Text.AlignHCenter
            }

            AppBusyIndicator {
                id: busyIndicator

                anchors.centerIn: parent

                width: 40 * AppFramework.displayScaleFactor
                height: width

                running: loader.status === Loader.Loading
            }

            AppText {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: busyIndicator.bottom
                    margins: 10 * AppFramework.displayScaleFactor
                }

                visible: loader.status === Loader.Error
                text: qsTr("Error loading add-in")
                color: "red"
                style: Text.Outline
                styleColor: "white"

                font {
                    pointSize: 20
                }
                horizontalAlignment: Text.AlignHCenter
            }

            ProgressBar {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 10 * AppFramework.displayScaleFactor
                }

                value: loader.progress
            }
        }
    }

    //--------------------------------------------------------------------------
}
