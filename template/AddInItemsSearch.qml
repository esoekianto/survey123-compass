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

import "../Portal"

PortalSearch {
    id: searchRequest
    
    property bool busy: false
    property AddInsModel addInsModel

    //--------------------------------------------------------------------------

    //        sortField: searchModel.sortProperty
    //        sortOrder: searchModel.sortOrder
    num: 25
    
    //--------------------------------------------------------------------------

    Component.onCompleted: {
        
    }
    
    //--------------------------------------------------------------------------

    onSuccess: {
        console.log("# results:", response.results.length);

        response.results.forEach(function (result) {
            addInsModel.appendItem(result);
        });
        
        if (response.nextStart > 0) {
            addInsModel.sort();
            search(response.nextStart);
        } else {
            addInsModel.sort();
            addInsModel.updated();
            busy = false;
        }
    }

    //--------------------------------------------------------------------------

    function startSearch() {
        var query = 'orgid:%1 AND type:"Code Sample" AND tags:"survey123addin"'.arg(portal.user.orgId);

        q = query;

        console.log("Searching for add-ins:", query);

        addInsModel.updateLocal();
        busy = true;
        search();
    }

    //--------------------------------------------------------------------------
}
