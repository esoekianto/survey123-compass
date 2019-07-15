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
import QtQuick.Layouts 1.1

import ArcGIS.AppFramework 1.0

Page {
    id: page

    title: qsTr("About %1").arg(app.info.title)

    //--------------------------------------------------------------------------

    property bool debug: false

    readonly property string kSurvey123Apps: "survey123_apps"
    readonly property string licenseAgreementText: qsTr("The license agreement for this application is <a href=\"%1\">here</a>.").arg("http://www.esri.com/legal/software-license")
    readonly property string descriptionText: qsTr("<p>Surveys, forms, polls, and questionnaires are really just the same thing: a list of questions. Questions, however, are one of the most powerful ways of gathering information for making decisions and taking action.</p></p>Survey123 for ArcGIS is a simple, lightweight, and intuitive data gathering solution that makes creating, sharing, and analyzing surveys possible in just three easy steps.</p>")

    property bool useItemInfoAboutText: app.info.owner !== kSurvey123Apps

    //--------------------------------------------------------------------------

    contentItem: ScrollView {
        id: scrollView

        Column {
            width: scrollView.width
            spacing: 10 * AppFramework.displayScaleFactor

            AboutText {
                text: qsTr("Version %1").arg(app.info.version + app.features.buildTypeSuffix)
                font {
                    pointSize: 14
                }
                horizontalAlignment: Text.AlignHCenter
            }

            AboutText {
                text: useItemInfoAboutText ? app.info.description : descriptionText
                textFormat: Text.RichText
            }

            AboutSeparator {
            }

            AboutText {
                text: "Copyright © 2019 Esri Inc. All Rights Reserved"
                horizontalAlignment: Text.AlignHCenter
            }

            Image {
                width: parent.width
                height: 50 * AppFramework.displayScaleFactor

                source: app.folder.fileUrl(app.info.propertyValue("companyLogo", ""))
                fillMode: Image.PreserveAspectFit

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally(app.info.propertyValue("companyUrl", ""))
                    }
                }
            }

            AboutSeparator {
            }

            AboutText {
                text: qsTr("License Agreement")
                font {
                    pointSize: 15
                    bold: true
                }
                horizontalAlignment: Text.AlignHCenter
            }

            AboutText {
                text: useItemInfoAboutText ? app.info.licenseInfo : licenseAgreementText
            }

            Column {
                id: footer

                anchors {
                    left: parent.left
                    right: parent.right
//                    margins: 10 * AppFramework.displayScaleFactor
                }

                spacing: 5 * AppFramework.displayScaleFactor

                AboutSeparator {
                }

                Item {
                    width: parent.width
                    height: 20 * AppFramework.displayScaleFactor

                    AboutLabelValue {
                        label: qsTr("AppFramework version:")
                        value: AppFramework.version
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    MouseArea {
                        anchors.fill: parent
                        onPressAndHold: {
                             debug = !debug;
                        }
                    }
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Device Architecture:")
                    value: (
                              function () {

                                  var systemInformation = AppFramework.systemInformation;

                                  if (Qt.platform.os === "android" && systemInformation.unixMachine !== undefined) {
                                      return systemInformation.unixMachine;
                                  }

                                  return AppFramework.currentCpuArchitecture;

                                // -----------------------------------------------------------------
                                }()
                              )
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Build Architecture:")
                    value: AppFramework.buildCpuArchitecture
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Qt version:")
                    value: AppFramework.qtVersion
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Operating system version:")
                    value: AppFramework.osVersion
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Kernel version:")
                    value: AppFramework.kernelVersion
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("SSL library version:")
                    value: AppFramework.sslLibraryVersion
                }

                AboutLabelValue {
                    property var locale: Qt.locale()

                    visible: debug
                    label: qsTr("Locale:")
                    value: "%1 %2".arg(locale.name).arg(locale.nativeLanguageName)
                }

                AboutSeparator {
                    visible: debug
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("User home path:")
                    value: AppFramework.userHomePath

                    onClicked: {
                        Qt.openUrlExternally(AppFramework.userHomeFolder.url);
                    }
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Surveys folder:")
                    value: surveysFolder.path

                    onClicked: {
                        Qt.openUrlExternally(surveysFolder.url);
                    }
                }

                AboutLabelValue {
                    visible: debug
                    label: qsTr("Maps library:")
                    value: surveysFolder.filePath("Maps")

                    onClicked: {
                        Qt.openUrlExternally(surveysFolder.fileUrl("Maps"));
                    }
                }

                AboutLabelValue {
                    visible: debug && portal.signedIn
                    label: "Token expiry:"
                    value: portal.expires.toLocaleString()
                }

                /*
            AboutText {
                text: qsTr("Attchments folder: %1").arg(surveysFolder.path)
            }
*/

            }
        }
    }
}
