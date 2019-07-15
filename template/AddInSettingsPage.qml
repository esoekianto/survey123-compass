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

Page {
    id: page

    title: qsTr("%1 Settings").arg(addIn.itemInfo.title)

    //--------------------------------------------------------------------------

    property bool debug: false
    property AddIn addIn
    property var instance

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        loader.setSource(addIn.settingsSource,
                         {
                             instance: instance
                         });
    }

    //--------------------------------------------------------------------------

    contentItem: Item {
        Loader {
            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }

            sourceComponent: backgroundComponent
            active: loader.status !== Loader.Ready
            asynchronous: true
        }

        Loader {
            id: loader

            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }
        }
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
                text: qsTr("Error loading settings")
                color: "red"
                style: Text.Outline
                styleColor: "white"

                font {
                    pointSize: 20
                }
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    //--------------------------------------------------------------------------

}
