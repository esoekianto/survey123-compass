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

import "../template/SurveyHelper.js" as Helper
import "../Models"
import "../Portal"
import "../XForms/XForm.js" as XFormJS

SortedListModel {
    id: addInsModel

    //--------------------------------------------------------------------------

    property AddInsFolder addInsFolder
    property bool showSurveysTile: false
    property url surveysTileThumbnail: "images/gallery-thumbnail.png"
    property string type: ""
    property bool includeDisabled: false

    //--------------------------------------------------------------------------

    readonly property string kTypeTile: "tile"
    readonly property string kTypeTab: "tab"
    readonly property string kTypeService: "service"
    readonly property string kTypeHidden: "hidden"

    //--------------------------------------------------------------------------

    signal updated();

    //--------------------------------------------------------------------------

    readonly property string kPropertyTitle: "title"
    readonly property string kPropertyModified: "modified"

    //--------------------------------------------------------------------------

    sortProperty: kPropertyTitle
    sortOrder: "asc"
    sortCaseSensitivity: Qt.CaseInsensitive

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Qt.callLater(update);
    }

    //--------------------------------------------------------------------------

    onShowSurveysTileChanged: {
        Qt.callLater(update);
    }

    //--------------------------------------------------------------------------

    readonly property Connections _connections: Connections {
        target: addInsFolder

        onAddInsChanged: {
            Qt.callLater(addInsModel.update);
        }
    }

    //--------------------------------------------------------------------------

    function update(updateFolder) {
        if (updateFolder) {
            addInsFolder.update();
        }

        updateLocal();
        updated();
    }

    //--------------------------------------------------------------------------

    function updateLocal() {
        console.log("Updating add-ins model");

        clear();

        if (showSurveysTile && type === kTypeTile) {
            var addInItem = {
                itemId: -1,
                path: "",
                folderName: "",
                title: "My Surveys",
                description: "",
                thumbnail: surveysTileThumbnail,
                modified: 0,
                owner: "",
                updateAvailable: false
            }

            append(addInItem);
        }

        addInsFolder.addIns.forEach(function (addInInfo) {
            if (type > "" && addInInfo.type !== type) {
                return;
            }

            var addInFolder = AppFramework.fileFolder(addInInfo.path);

            var itemInfo = addInFolder.readJsonFile("iteminfo.json");

            var thumbnail = Helper.findThumbnail(addInFolder, "thumbnail", "images/addIn-thumbnail.png");
            var title = itemInfo.title || "Unknown title";
            var description = itemInfo.description || "";
            var itemId = itemInfo.id || "";
            var owner = itemInfo.owner || "";

            var addInItem = {
                itemId: itemId,
                path: addInInfo.path,
                folderName: addInInfo.folderName,
                title: title,
                description: description,
                thumbnail: thumbnail,
                modified: itemInfo.modified,
                owner: owner,
                updateAvailable: false,
                enabled: XFormJS.toBoolean(addInInfo.enabled, true)
            }

            if (addInItem.enabled || includeDisabled) {
                append(addInItem);
            }

            //console.log("addInItem:", JSON.stringify(addInItem, undefined, 2));
        });

        sort();

        console.log("Updated add-ins model count:", count, "type:", type);
    }

    //--------------------------------------------------------------------------

    function appendItem(itemInfo) {
        var itemId = itemInfo.id;

        for (var i = 0; i < count; i++) {
            var item = get(i);
            if (item.itemId === itemId) {
                var updated = itemInfo.modified > item.modified;
                setProperty(i, "updateAvailable", updated);
                return;
            }
        }

        var addInItem = {
            itemId: itemId,
            path: "",
            title: itemInfo.title,
            description: itemInfo.description,
            thumbnail: itemInfo.thumbnail,
            modified: itemInfo.modified,
            owner: itemInfo.owner,
            updateAvailable: true
        };

        append(addInItem);
    }

    //--------------------------------------------------------------------------

    function run(addInInfo) {

    }

    //--------------------------------------------------------------------------

    function edit(addInInfo) {

    }

    //--------------------------------------------------------------------------

    function upload(addInInfo) {

    }

    //--------------------------------------------------------------------------
}
