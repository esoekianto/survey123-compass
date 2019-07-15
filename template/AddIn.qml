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

Item {
    id: addIn

    //--------------------------------------------------------------------------

    property alias path: folder.path
    property alias folder: folder

    property var addInInfo
    property var itemInfo

    property string title
    property url thumbnail: "images/add-in.png"
    property url iconSource: "images/add-in.png"
    property url mainSource
    property string version

    property url settingsSource
    readonly property bool hasSettings: settingsSource > ""

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        addInInfo = folder.readJsonFile("addin.json");
        itemInfo = folder.readJsonFile("iteminfo.json");

        console.log("addInInfo:", JSON.stringify(addInInfo, undefined, 2));

        mainSource = folder.fileUrl(addInInfo.mainFile);

        title = itemInfo.title || "Untitled Add-In";
        thumbnail = folder.fileUrl("thumbnail.png")
        if (folder.fileExists(addInInfo.icon)) {
            iconSource = folder.fileUrl(addInInfo.icon);
        }

        if (addInInfo.settingsFile > "" && folder.fileExists(addInInfo.settingsFile)) {
            settingsSource = folder.fileUrl(addInInfo.settingsFile);
        }

        version = toVersionString(addInInfo.version);
    }

    //--------------------------------------------------------------------------

    function toVersionString(version) {
        if (!version) {
            version = {};
        }
        if (!version.major) {
            version.major = 0;
        }
        if (!version.minor) {
            version.minor = 0;
        }
        if (!version.micro) {
            version.micro = 0;
        }

        return "%1.%2.%3".arg(version.major).arg(version.minor).arg(version.micro);
    }

    //--------------------------------------------------------------------------

    FileFolder {
        id: folder
    }

    //--------------------------------------------------------------------------
}
