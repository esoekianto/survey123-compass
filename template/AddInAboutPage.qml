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
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

Page {
    id: page

    title: qsTr("About %1").arg(itemInfo.title)

    //--------------------------------------------------------------------------

    property bool debug: false
    property AddIn addIn
    property var addInInfo: addIn.addInInfo
    property var itemInfo: addIn.itemInfo

    //--------------------------------------------------------------------------

    contentItem: Item {
        Image {
            anchors {
                fill: parent
                margins: -parent.anchors.margins
            }

            asynchronous: true
            source: addIn.thumbnail
            fillMode: Image.PreserveAspectCrop
            opacity: 0.1
            cache: false
        }

        ScrollView {
            id: scrollView

            anchors {
                fill: parent
                margins: 10 * AppFramework.displayScaleFactor
            }

//            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

//            clip: true

            Column {
                width: scrollView.width
                spacing: 5 * AppFramework.displayScaleFactor

                Image {
                    width: parent.width
                    height: 133 * AppFramework.displayScaleFactor

                    asynchronous: true
                    source: addIn.thumbnail
                    cache: false
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.paintedWidth
                        height: parent.paintedHeight

                        color: "transparent"
                        border {
                            width: 1
                            color: "#40000000"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: {
                            var url = app.portal.portalUrl + "/home/item.html?id=" + addIn.itemInfo.id;
                            console.log("Opening:", url);
                            Qt.openUrlExternally(url);
                        }
                    }
                }

                AboutText {
                    text: itemInfo.snippet || ""

                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 15
                    }
                }

                AboutText {
                    text: qsTr("Version %1").arg(addIn.version)
                    font {
                        pointSize: 14
                    }
                    horizontalAlignment: Text.AlignHCenter
                }

                AboutText {
                    property string owner: itemInfo.owner || ""

                    visible: owner > ""
                    text: qsTr("Owned by %1").arg(owner)

                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 12
                    }
                }

                AboutText {
                    Layout.fillWidth: true

                    property date modified: new Date(itemInfo.modified)

                    visible: isFinite(modified.valueOf())
                    text: qsTr("Last modified on %1 at %2").arg(modified.toLocaleDateString(page.locale)).arg(modified.toLocaleTimeString(page.locale))
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 12
                    }
                }

                AboutSeparator {
                }

                AboutText {
                    text: itemInfo.description || ""
                    horizontalAlignment: Text.AlignHCenter
                }

                AboutSeparator {
                    visible: licenseInfoText.visible
                }

                AboutText {
                    text: qsTr("License Agreement")
                    font {
                        pointSize: 15
                        bold: true
                    }
                    horizontalAlignment: Text.AlignHCenter
                    visible: licenseInfoText.visible
                }

                AboutText {
                    id: licenseInfoText

                    text: itemInfo.licenseInfo || ""
                    visible: text > ""
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
