/* Copyright 2015 Esri
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

import QtQuick 2.4

import ArcGIS.AppFramework 1.0

Item {
    id: portalItem

    property Portal portal
    property string folderId
    property string itemId
    readonly property url itemUrl: portal.owningSystemUrl + "/home/item.html?id=" + itemId
    readonly property url userContentUrl: portal.restUrl + "/content/users/" + portal.username + (folderId > "" ? "/" + folderId : "")
    readonly property url contentUrl: portal.restUrl + "/content/items/" + itemId

    property var itemInfo
    property real progress: 0

    signal added()
    signal updated()
    signal deleted()
    signal published(var service)
    signal downloaded(string path)
    signal itemInfoDownloaded()
    signal thumbnailRequestComplete(string path)
    signal contentFileReceived(var content)
    signal failed(var error)

    //--------------------------------------------------------------------------

    function addItem(itemInfo) {
        console.log("addItem", JSON.stringify(itemInfo, undefined, 2));
        addItemRequest.sendRequest(itemInfo);
    }

    function update(itemInfo) {
        console.log("update", JSON.stringify(itemInfo, undefined, 2));
        updateRequest.sendRequest(itemInfo);
    }

    function deleteItem(id) {
        if (id) {
            itemId = id;
        }

        console.log("deleteItem", itemId);

        deleteRequest.sendRequest();
    }

    function publishItem(publishData) {
        console.log("publishItem", itemId); //JSON.stringify(publishData, undefined, 2));
        publishRequest.sendRequest(publishData);
    }

    function requestInfo(user) {
        if (user) {
            userItemRequest.sendRequest();
        } else {
            infoRequest.sendRequest();
        }
    }

    function download(filePath) {
        dataRequest.responsePath = filePath;

        dataRequest.sendRequest();
    }

    function downloadThumbnail(path) {
        if (!itemInfo.thumbnail) {
            thumbnailRequestComplete(null)
//            console.warn("No thumbnail for:", itemId);
            return false;
        }

//        console.log("downloadThumbnail:", itemId, path);

        AppFramework.fileInfo(path).folder.makeFolder();

        thumbnailRequest.responsePath = path;
        thumbnailRequest.url = contentUrl + "/info/" + itemInfo.thumbnail;

        thumbnailRequest.sendRequest();

        return true;
    }

    function downloadSurveyThumbnail(path) {
        if (!itemInfo.thumbnail) {
            thumbnailRequestComplete(null);
//            console.warn("No thumbnail for:", itemId);
            return false;
        }

        if (itemInfo.thumbnail === null || itemInfo.thumbnail === "") {
            thumbnailRequestComplete(null);
//            console.warn("No thumbnail for:", itemId);
            return false;
        }

        var fileName = itemInfo.thumbnail;

        if (fileName.search(/^thumbnail\//) > -1) {
            fileName = fileName.substring(fileName.indexOf("/") + 1, fileName.length);
        }

        if (fileName === "" || fileName === undefined) {
            fileName = surveyInfo.name.toString() + ".png";
        }

        AppFramework.fileInfo(path).folder.makeFolder();

        thumbnailRequest.responsePath = "%1/%2".arg(path).arg(fileName);
        thumbnailRequest.url = contentUrl + "/info/" + itemInfo.thumbnail;

        if (AppFramework.fileFolder(path).fileExists(fileName)){
            thumbnailRequestComplete(thumbnailRequest.responsePath);
            return;
        }

        thumbnailRequest.sendRequest();
    }

    function requestRelatedItems(relationshipType, direction) {
        if (!direction) {
            direction = "forward";
        }

        relatedItemsRequest.sendRequest({
                                            "direction": direction
                                        });
    }

    //--------------------------------------------------------------------------

    function requestContentFile(fileName) {
        contentFileRequest.url = contentUrl + "/info/%1".arg(fileName);

        console.log("Requesting content file:", fileName, "url:", contentFileRequest.url);

        contentFileRequest.sendRequest();
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: addItemRequest

        portal: portalItem.portal
        url: userContentUrl + "/addItem"

        onSuccess: {
            console.log("addItem", JSON.stringify(response, undefined, 2));

            itemId = response.id;

            //console.log("addItem itemUrl:", itemUrl);
            //console.log("addItem contentUrl:", contentUrl);

            added();
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: updateRequest

        portal: portalItem.portal
        url: userContentUrl + "/items/" + itemId + "/update"

        onSuccess: {
            console.log("updateItem", JSON.stringify(response, undefined, 2));

            updated();
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: deleteRequest

        portal: portalItem.portal
        url: userContentUrl + "/items/" + itemId + "/delete"

        onSuccess: {
            console.log("deleteItem", JSON.stringify(response, undefined, 2));

            deleted();
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: publishRequest

        portal: portalItem.portal
        url: userContentUrl + "/publish"

        onSuccess: {
            console.log("publishItem", JSON.stringify(response, undefined, 2));

            published(response.services[0]);
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: infoRequest

        portal: portalItem.portal
        url: contentUrl

        onSuccess: {
            //console.log("itemInfo", JSON.stringify(response, undefined, 2));

            itemInfo = response;
            itemInfoDownloaded();
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: userItemRequest

        portal: portalItem.portal
        url: userContentUrl + "/" + itemId

        onSuccess: {
            console.log("userItem", JSON.stringify(response, undefined, 2));
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: dataRequest

        portal: portalItem.portal
//        url: userContentUrl + "/" + itemId + "/data"
        url: contentUrl + "/data"
        responseType: "zip"
        method: "GET"

        onSuccess: {
            downloaded(responsePath);
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    PortalRequest {
        id: thumbnailRequest

        portal: portalItem.portal
        method: "GET"
        responseType: "application/octet-stream"

        onSuccess: {
            thumbnailRequestComplete(responsePath);
        }

        onFailed: {
            thumbnailRequestComplete(null);
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    //--------------------------------------------------------------------------

    PortalRequest {
        id: contentFileRequest

        portal: portalItem.portal
        method: "GET"

        onSuccess: {
            contentFileReceived(response);
        }

        onFailed: {
            portalItem.failed(error);
        }

        onProgressChanged: {
            portalItem.progress = progress;
        }
    }

    //--------------------------------------------------------------------------
}
