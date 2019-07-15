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
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.3
import QtQuick.Dialogs 1.2

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Networking 1.0
import ArcGIS.AppFramework.InterAppCommunication 1.0

import "../Controls"

SettingsTab {

    title: qsTr("Storage")
    description: qsTr("Manage local data")
    icon: "images/data.png"

    //--------------------------------------------------------------------------

    readonly property string kFolderSeparator: ";"
    readonly property bool canModifyMapLibrary: Qt.platform.os !== "ios"

    property color hoveredColor: "#ff8082"
    property color pressedColor: "#ff4a4d"

    //--------------------------------------------------------------------------

    property bool allowEmailData: false

    //--------------------------------------------------------------------------

    onTitlePressAndHold: {
        allowEmailData = !allowEmailData;
    }

    //--------------------------------------------------------------------------

    Item {
        property string mapFoldersText: mapLibraryTextField.text.trim()
        property var mapFolderNames: []

        //----------------------------------------------------------------------

        Component.onDestruction: {
            updateSettings();
        }

        //----------------------------------------------------------------------

        onMapFoldersTextChanged: {
            mapFolderNames = mapFoldersText.split(kFolderSeparator).filter(function (name) {
                return name && name.trim() > "";
            });
        }

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 20 * AppFramework.displayScaleFactor

            //------------------------------------------------------------------

            GroupColumnLayout {
                Layout.fillWidth: true

                title: qsTr("Map library")

                ColumnLayout {
                    Layout.fillWidth: true

                    visible: canModifyMapLibrary

                    AppText {
                        Layout.fillWidth: true

                        text: qsTr("Folders: %1").arg(mapFolderNames.length)

                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                        MouseArea {
                            anchors.fill: parent

                            onPressAndHold: {
                                mapFolderNames.forEach(function (name) {
                                    var folder = AppFramework.fileFolder(name);
                                    console.log("Map folder:", folder.path, "exists:", folder.exists);
                                    if (folder.exists) {
                                        Qt.openUrlExternally(folder.url);
                                    }
                                });
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        AppTextField {
                            id: mapLibraryTextField

                            Layout.fillWidth: true

                            text: appSettings.mapLibraryPaths
                        }

                        StyledImageButton {
                            Layout.preferredWidth: 35 * AppFramework.displayScaleFactor
                            Layout.preferredHeight: 35 * AppFramework.displayScaleFactor

                            source: "images/folder-plus-f.png"
                            color: app.textColor

                            onClicked: {
                                if (mapFolderNames.length > 0) {
                                    var folder = AppFramework.fileFolder(mapFolderNames[0]);
                                    console.log("library:", folder.url);
                                    mapLibraryDialog.folder = folder.url;
                                } else {
                                    mapLibraryDialog.folder = mapLibraryDialog.shortcuts.home;
                                }

                                mapLibraryDialog.open();
                            }

                            onPressAndHold: {
                                storageComboBox.visible = !storageComboBox.visible;
                            }
                        }
                    }

                    ComboBox {
                        id: storageComboBox

                        Layout.fillWidth: true

                        visible: false
                        model: storageInfo.mountedVolumes
                        textRole: "displayName"

                        onActivated: {
                            if (mapLibraryTextField.text.trim() > "") {
                                mapLibraryTextField.text += kFolderSeparator;
                            }

                            mapLibraryTextField.text += storageInfo.mountedVolumes[index].folder.path;
                        }

                        Component.onCompleted: {
                            currentIndex = -1;
                        }

                        StorageInfo {
                            id: storageInfo
                        }
                    }
                }

                AppButton {
                    Layout.fillWidth: true

                    text: qsTr("View map library")

                    onClicked: {
                        if (Networking.isOnline) {
                            showSignInOrMapsPage();
                        } else {
                            showMapsPage();
                        }
                    }

                    function showSignInOrMapsPage() {
                        portal.signInAction(qsTr("Please sign in to manage the maps library"), showMapsPage);
                    }

                    function showMapsPage() {
                        updateSettings();
                        page.Stack.view.push(mapLibraryPage);
                    }
                }
            }

            //------------------------------------------------------------------

            Item {
                Layout.fillHeight: true
            }

            //------------------------------------------------------------------

            AppButton {
                Layout.fillWidth: true

                visible: allowEmailData
                text: qsTr("Email surveys database")
                iconSource: "images/envelope.png"

                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor
                activateColor: "#90cdf2"

                onClicked: {
                    emailDatabase();
                }
            }

            //------------------------------------------------------------------

            AppButton {
                //            Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                text: qsTr("Reinitialize Database")
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor

                onClicked: {
                    confirmPanel.clear();
                    confirmPanel.icon = "images/warning.png";
                    confirmPanel.title = text;
                    confirmPanel.text = qsTr("This action will reinitialize the survey database and delete all collected survey data.");
                    confirmPanel.question = qsTr("Are you sure you want to reinitialize the database?");

                    confirmPanel.show(function () {
                        surveysDatabase.reinitialize();
                    });
                }
            }

            AppButton {
                Layout.fillWidth: true

                text: qsTr("Fix Database")
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor

                onClicked: {
                    onClicked: {
                        confirmPanel.clear();
                        confirmPanel.icon = "images/warning.png";
                        confirmPanel.title = text;
                        confirmPanel.text = qsTr("This action will fix the survey database and reconnect the database with the app.");
                        confirmPanel.question = qsTr("Are you sure you want to fix the database?");

                        confirmPanel.show(function () {
                            surveysDatabase.fixSurveysPath();
                        });
                    }
                }
            }

            AppButton {
                //            Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true


                text: qsTr("Delete Submitted Surveys")
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor

                onClicked: {
                    confirmPanel.clear();
                    confirmPanel.icon = "images/warning.png";
                    confirmPanel.title = text;
                    confirmPanel.text = qsTr("This action will delete any surveys that have been submitted.");
                    confirmPanel.question = qsTr("Are you sure you want to delete the submitted surveys?");

                    confirmPanel.show(function () {
                        surveysDatabase.deleteSurveys(surveysDatabase.statusSubmitted);
                    });
                }
            }

            AppButton {
                //            Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true


                property FileFolder cacheFolder: AppFramework.standardPaths.writableFolder(StandardPaths.GenericCacheLocation).folder("QtLocation/ArcGIS")

                visible: cacheFolder.exists
                text: qsTr("Clear Map Cache (%1 Mb)").arg(mb(cacheFolder.size))
                hoveredBackgroundColor: hoveredColor
                pressedBackgroundColor: pressedColor
                activateDelay: 1500
                activateColor: "#90cdf2"

                onClicked: {
                    if (checked) {
                        checked = false;
                    } else {
                        console.log("Removing cache folder:", cacheFolder.path);
                        confirmPanel.clear();
                        confirmPanel.icon = "images/warning.png";
                        confirmPanel.title = text;
                        confirmPanel.text = qsTr("This action will delete any maps that have been cached.");
                        confirmPanel.question = qsTr("Are you sure you want to delete the chached maps?");

                        confirmPanel.show(function () {
                            cacheFolder.removeFolder();
                        });
                    }
                }

                onActivated: {
                    checked = false;
                    Qt.openUrlExternally(cacheFolder.url);
                }

                function mb(bytes) {
                    var mb = bytes / 1048576;

                    return mb.toFixed(2);
                }
            }

        }

        //----------------------------------------------------------------------

        EmailComposer {
            id: emailComposer

            subject: qsTr("Survey123 Database")
            html: true

            onComposeError: {
                console.error("Composer error:", JSON.stringify(reason));
            }
        }

        function emailDatabase() {
            var fileName = Qt.md5(surveysDatabase.dbIdentifer) + ".sqlite";
            var fileInfo = AppFramework.fileFolder(AppFramework.offlineStoragePath).folder("Databases").fileInfo(fileName);
            var filePath = fileInfo.filePath; //fileInfo.url.toString();

            console.log("Email database:", filePath);

            emailComposer.body =
                    "<p>Survey123 Version: %1</p>\r\n".arg(app.info.version) +
                    "<p>Operating system: %1 - %2</p>\r\n".arg(Qt.platform.os).arg(AppFramework.osVersion) +
                    "<p>Locale: %1</p>\r\n".arg(Qt.locale().name);

            emailComposer.attachments = [
                        filePath
                    ];

            emailComposer.show();
        }

        //----------------------------------------------------------------------

        FileDialog {
            id: mapLibraryDialog

            title: qsTr("Map Library Folder")
            selectFolder: true
            selectExisting: true

            onAccepted: {
                var fileInfo = AppFramework.fileInfo(folder);

                var folders = mapLibraryTextField.text.trim();
                if (folders > "") {
                    folders += kFolderSeparator + fileInfo.filePath;
                } else {
                    folders = fileInfo.filePath;
                }

                mapLibraryTextField.text = folders;
            }
        }

        //--------------------------------------------------------------------------

        Component {
            id: mapLibraryPage

            MapLibraryPage {
            }
        }

        //--------------------------------------------------------------------------

        ConfirmPanel {
            id: confirmPanel
        }

        //----------------------------------------------------------------------

        function updateSettings() {
            if (canModifyMapLibrary) {
                var paths = mapLibraryTextField.text.trim();

                if (paths.length <= 0) {
                    paths = appSettings.kDefaultMapLibraryPath;
                }

                appSettings.mapLibraryPaths = paths;
            }

        }

        //----------------------------------------------------------------------
    }
}
