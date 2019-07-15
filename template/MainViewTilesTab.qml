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

import "../Models"

MainViewTab {
    id: tab

    //--------------------------------------------------------------------------

    property alias gridView: galleryView
    property bool showSurveysTile: /*addInTilesModel.count > 0 &&*/ settings.boolValue("AddIns/showSurveysTile", false);

    readonly property bool showSearchField: tilesModel.count > 6

    //--------------------------------------------------------------------------

    title: app.info.title
    shortTitle: qsTr("Gallery")
    iconSource: "images/tiles.png"

    //--------------------------------------------------------------------------

    menu: AppMenu {
    }

    //--------------------------------------------------------------------------

    function updateTiles() {
        console.log("Updating tiles");

        tilesModel.clear();

        if (!showSurveysTile) {
            for (var i = 0; i < surveysModel.count; i++) {
                var surveyItem = surveysModel.get(i);

                surveyItem.tileType = tilesModel.kTileTypeSurvey;

                tilesModel.append(surveyItem);
            }
        }

        for (i = 0; i < addInTilesModel.count; i++) {
            var addInItem = addInTilesModel.get(i);

            addInItem.tileType = tilesModel.kTileTypeAddIn;

            tilesModel.append(addInItem);
        }

        tilesModel.sort();

        if (showSearchField) {
            filteredTilesModel.update();
        }

        galleryView.forceLayout();
    }

    //--------------------------------------------------------------------------

    FilteredListModel {
        id: filteredTilesModel

        sourceModel: tilesModel
        baseItems: 0
        filterText: searchField.text
    }

    //--------------------------------------------------------------------------

    SortedListModel {
        id: tilesModel

        //--------------------------------------------------------------------------

        readonly property string kPropertyTitle: "title"
        readonly property string kPropertyModified: "modified"

        //--------------------------------------------------------------------------

        readonly property string kTileTypeAddIn: "addin"
        readonly property string kTileTypeSurvey: "survey"

        //--------------------------------------------------------------------------

        sortProperty: kPropertyTitle
        sortOrder: "asc"
        sortCaseSensitivity: Qt.CaseInsensitive
    }

    //--------------------------------------------------------------------------

    AddInsModel {
        id: addInTilesModel

        type: kTypeTile
        addInsFolder: app.addInsFolder
        showSurveysTile: tab.showSurveysTile

        onUpdated: {
            Qt.callLater(updateTiles);
        }
    }

    //--------------------------------------------------------------------------

    SurveysModel {
        id: surveysModel

        enabled: !showSurveysTile
        formsFolder: surveysFolder

        onUpdated: {
            Qt.callLater(updateTiles);
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            topMargin: 5 * AppFramework.displayScaleFactor
        }

        SearchField {
            id: searchField

            Layout.fillWidth: true
            Layout.leftMargin: 5 * AppFramework.displayScaleFactor
            Layout.rightMargin: Layout.leftMargin

            visible: showSearchField
            focus: false
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: !scrollView.visible
        }

        ScrollView {
            id: scrollView

            Layout.fillWidth: true
            Layout.fillHeight: true

            visible: galleryView.model.count

            GalleryView {
                id: galleryView

                focus: true
                model: showSearchField ? filteredTilesModel.visualModel : tilesModel

                delegate: tileDelegate

                onClicked: {
                    var tileItem = model.get(currentIndex);

                    switch (tileItem.tileType) {
                    case tilesModel.kTileTypeAddIn:
                        addInSelected(tileItem);
                        break;

                    case tilesModel.kTileTypeSurvey:
                        selected(app.surveysFolder.filePath(tileItem.path), false, -1, null);
                        break;
                    }
                }

                onPressAndHold: {
                    var tileItem = model.get(currentIndex);

                    switch (tileItem.tileType) {
                    case tilesModel.kTileTypeAddIn:
                        break;

                    case tilesModel.kTileTypeSurvey:
                        selected(app.surveysFolder.filePath(tileItem.path), true, -1, null);
                        break;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: tileDelegate

        Item {
            id: item

            property int _index: index
            property string _path: path
            property string _thumbnail: thumbnail
            property string _title: title

            Loader {
                id: loader

                property alias index: item._index
                property alias path: item._path
                property alias thumbnail: item._thumbnail
                property alias title: item._title

                asynchronous: true

                sourceComponent: {
                    var tileItem = galleryView.model.get(index);
                    if (!tileItem) {
                        return;
                    }

                    switch (tileItem.tileType) {
                    case tilesModel.kTileTypeAddIn:
                        return addInTileDelegate;

                    case tilesModel.kTileTypeSurvey:
                        return surveyTileDelegate;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInTileDelegate

        GalleryDelegate {
            galleryView: gridView

            onClicked: {
                galleryView.currentIndex = index;
                galleryView.clicked();
            }

            onPressAndHold: {
                galleryView.currentIndex = index;
                galleryView.pressAndHold();
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: surveyTileDelegate

        SurveysGalleryDelegate {
            galleryView: gridView
        }
    }

    //--------------------------------------------------------------------------
}
