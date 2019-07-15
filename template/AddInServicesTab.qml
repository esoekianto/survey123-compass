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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

MainViewTab {
    //--------------------------------------------------------------------------

    property AddInServicesManager manager
    readonly property int count: manager.services.length

    //--------------------------------------------------------------------------

    title: qsTr("Services")
    iconSource: "images/add-in.png"

    //--------------------------------------------------------------------------

    ListView {
        anchors {
            fill: parent
            margins: 5 * AppFramework.displayScaleFactor
        }

        clip: true
        model: manager.services
        spacing: 0
        delegate: serviceDelegate
    }

    //--------------------------------------------------------------------------

    Component {
        id: serviceDelegate

        Item {
            readonly property AddInService service: ListView.view.model[index]
            readonly property AddInContainer container: service.container
            readonly property AddIn addIn: service.addIn

            width: ListView.view.width
            height: childrenRect.height + 5 * AppFramework.displayScaleFactor

            RowLayout {
                width: parent.width
                spacing: 5 * AppFramework.displayScaleFactor

                Image {
                    Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: 66 * AppFramework.displayScaleFactor

                    source: addIn.thumbnail
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            mainStackView.push(addInAboutPage,
                                               {
                                                   addIn: addIn,
                                               });
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.margins: 5 * AppFramework.displayScaleFactor
                    spacing: 2 * AppFramework.displayScaleFactor

                    AppText {
                        Layout.fillWidth: true

                        text: container.title
                        font {
                            pointSize: 14
                        }
                    }

                    AppText {
                        Layout.fillWidth: true

                        text: addIn.version
                        font {
                            pointSize: 10
                        }
                    }
                }

                Item {
                    Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth

                    StyledImageButton {
                        anchors.fill: parent

                        visible: addIn.hasSettings
                        source: "images/gear.png"
                        color: "#7f8183"

                        onClicked: {
                            mainStackView.push(addInSettingsPage,
                                               {
                                                   addIn: addIn,
                                                   instance: service.instance
                                               });
                        }
                    }
                }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                }

                height: 1
                color: "#40000000"
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInAboutPage

        AddInAboutPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInSettingsPage

        AddInSettingsPage {
        }
    }

    //--------------------------------------------------------------------------
}
