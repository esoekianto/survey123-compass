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
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

import "../Controls"
import "../Portal"

SettingsTab {
    id: tab

    //--------------------------------------------------------------------------

    title: qsTr("Add-Ins")
    description: qsTr("View and manage add-ins")
    icon: "images/add-in.png"

    //--------------------------------------------------------------------------

    property Portal portal
    property bool debug: true

    readonly property string kSettingShowSurveysTile: "AddIns/showSurveysTile"
    readonly property string kSettingShowServicesTab: "AddIns/showServicesTab"

    //--------------------------------------------------------------------------

    Item {

        Component.onDestruction: {
            settings.setValue(kSettingShowSurveysTile, showSurveysTileSwitch.checked, false);
            settings.setValue(kSettingShowServicesTab, showServicesTabSwitch.checked, false);
        }

        //----------------------------------------------------------------------

        ColumnLayout {
            anchors {
                fill: parent
                margins: 5 * AppFramework.displayScaleFactor
            }

            spacing: 5 * AppFramework.displayScaleFactor

            AppSwitch {
                id: showSurveysTileSwitch

                Layout.fillWidth: true

                text: qsTr("Show surveys as a tile")
                checked: settings.boolValue(kSettingShowSurveysTile, false);
            }

            AppSwitch {
                id: showServicesTabSwitch

                Layout.fillWidth: true

                text: qsTr("Show services tab")
                checked: settings.boolValue(kSettingShowServicesTab, false);
            }

            Rectangle {
                Layout.fillWidth: true

                height: 1 * AppFramework.displayScaleFactor
                color: "#80808080"
            }

            AppText {
                Layout.fillWidth: true

                text: qsTr("Pull to refresh add-ins available in your organisation.")

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                horizontalAlignment: Text.AlignHCenter
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                model: addInsModel
                spacing: 5 * AppFramework.displayScaleFactor
                clip: true

                delegate: addInDelegate

                RefreshHeader {
                    refreshing: addInItemsSearch.busy

                    onRefresh: {
                        portal.signInAction(qsTr("Please sign in to refresh add-ins"), addInItemsSearch.startSearch);
                    }
                }
            }
        }

        //----------------------------------------------------------------------
/*
        ButtonGroup {
            id: addInsGroup

            property RadioButton lastButton: null

            onClicked: {
                if (lastButton == button || button.addInItem.folderName === autoStart) {
                    button.checked = false;
                    lastButton = null;
                    autoStart = "";
                } else {
                    lastButton = button;
                    autoStart = button.addInItem.folderName;
                }
            }
        }
*/
        //----------------------------------------------------------------------

        AddInsModel {
            id: addInsModel

            addInsFolder: app.addInsFolder
        }

        //--------------------------------------------------------------------------

        AddInItemsSearch {
            id: addInItemsSearch

            portal: tab.portal
            addInsModel: addInsModel
        }

        //--------------------------------------------------------------------------

        AddInDownload {
            id: addInDownload

            portal: tab.portal
            progressPanel: progressPanel
            workFolder: app.workFolder
            addInsFolder: app.addInsFolder
            debug: debug

            onSucceeded: {
                addInsModel.update(true);
                //                page.downloaded = true;
                //                //surveysFolder.update();
                //                searchModel.update();
            }
        }

        //--------------------------------------------------------------------------

        ProgressPanel {
            id: progressPanel

            progressBar.visible: progressBar.value > 0
        }

        //----------------------------------------------------------------------

        Component {
            id: addInDelegate

            Rectangle {
                id: addInView

                property var addInItem: ListView.view.model.get(index)

                width: ListView.view.width
                height: rowLayout.height + rowLayout.anchors.margins * 2
                radius: 4

                color: mouseArea.containsMouse ? mouseArea.pressed ? "#90cdf2" : "#e1f0fb" : "transparent" //"#fefefe"
                border {
                    width: 1
                    color: "#e5e6e7"
                }

                AddIn {
                    id: addIn

                    path: addInItem.path
                }

                MouseArea {
                    id: mouseArea

                    anchors.fill: parent

                    hoverEnabled: true

                    onClicked: {
                        if (portal.signedIn && updateAvailable) {
                            addInDownload.download(addInView.ListView.view.model.get(index));
                        }
                    }

                    onPressAndHold: {
                        if (path > "") {
                            confirmDelete(index);
                        }
                    }
                }

                RowLayout {
                    id: rowLayout

                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 5 * AppFramework.displayScaleFactor
                    }
/*
                    RadioButton {
                        id: radioButton

                        property var addInItem: addInView.ListView.view.model.get(index)

                        ButtonGroup.group: addInsGroup
                        //checked: folderName == autoStart
                        enabled: folderName > ""

                        indicator: Rectangle {
                            implicitWidth: 26 * AppFramework.displayScaleFactor
                            implicitHeight: 26 * AppFramework.displayScaleFactor
                            x: radioButton.leftPadding
                            y: parent.height / 2 - height / 2

                            radius: width / 2
                            border.color: radioButton.down ? "grey" : "darkgrey"
                            visible: radioButton.enabled

                            Image {
                                id: playIcon

                                anchors {
                                    fill: parent
                                    margins: 5 * AppFramework.displayScaleFactor
                                    leftMargin: 7 * AppFramework.displayScaleFactor
                                }

                                source: "images/play-16-f.svg"
                                visible: false
                            }

                            ColorOverlay {
                                anchors.fill: playIcon
                                source: playIcon
                                color: "green"
                                visible: radioButton.checked
                            }
                        }
                    }
*/
                    Image {
                        Layout.preferredWidth: 100 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: 66 * AppFramework.displayScaleFactor
                        source: path > ""
                                ? thumbnail
                                : portal.restUrl + "/content/items/" + itemId + "/info/" + thumbnail + "?token=" + portal.token
                        fillMode: Image.PreserveAspectFit

                        Rectangle {
                            anchors {
                                fill: parent
                                margins: -1
                            }

                            color: "transparent"
                            border {
                                width: 1
                                color: "#30000000"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                mainStackView.push(addInAboutPage,
                                                   {
                                                       addIn: addIn
                                                   });
                            }

                            onPressAndHold: {
                                var url = addInsFolder.fileUrl(folderName);
                                console.log("Add-In:", url);
                                Qt.openUrlExternally(url);
                            }
                        }
                    }

                    Column {
                        Layout.fillWidth: true

                        spacing: 3 * AppFramework.displayScaleFactor

                        AppText {
                            width: parent.width
                            text: title
                            font {
                                pointSize: 16 * app.textScaleFactor
                            }
                            color: "#323232"
                        }

                        AppText {
                            width: parent.width
                            text: addIn.version
                            font {
                                pointSize: 11 * app.textScaleFactor
                            }
                            color: "#323232"
                        }

                        AppText {
                            width: parent.width
                            text: qsTr("Updated %1").arg(new Date(modified).toLocaleString(undefined, Locale.ShortFormat))
                            font {
                                pointSize: 11 * app.textScaleFactor
                            }
                            textFormat: Text.AutoText
                            color: "#7f8183"
                        }
                    }

                    StyledImageButton {
                        Layout.preferredWidth: 44 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        visible: portal.signedIn && updateAvailable

                        source: path > ""
                                ? "images/cloud-refresh.png"
                                : "images/cloud-download.png"

                        onClicked: {
                            addInDownload.download(addInView.ListView.view.model.get(index));
                        }
                    }

                    StyledImageButton {
                        Layout.preferredWidth: 40 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        visible: addIn.hasSettings

                        source: "images/gear.png"
                        color: "#7f8183"

                        onClicked: {
                            mainStackView.push(addInSettingsPage,
                                               {
                                                   addIn: addIn
                                               });
                        }
                    }
                }
            }
        }

        //----------------------------------------------------------------------

        function confirmDelete(index) {
            var title = addInsModel.get(index).title;

            confirmPanel.index = index;
            confirmPanel.clear();
            confirmPanel.icon = "images/warning.png";
            confirmPanel.title = qsTr("Delete Add-In");
            confirmPanel.text = qsTr("This action will delete the <b>%1</b> from this device.").arg(title);
            confirmPanel.question = qsTr("Are you sure you want to delete the add-in?");

            confirmPanel.show(deleteAddIn);
        }

        function deleteAddIn() {
            var path = addInsModel.get(confirmPanel.index).path;
            console.log("Delete add-in:", path);
            if (!addInsModel.addInsFolder.removeFolder(path, true)) {
                console.error("Error deleting add-in:", path);
            }

            addInsModel.update(true);
        }

        ConfirmPanel {
            id: confirmPanel

            property int index

            parent: app
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

        //----------------------------------------------------------------------
    }

    //--------------------------------------------------------------------------
}
