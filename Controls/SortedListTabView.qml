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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import QtQml.Models 2.3

import ArcGIS.AppFramework 1.0

Item {
    default property alias contentData: container.data
    property alias listTabView: listTabViewListView

    property alias tabViewContainer: container
    property alias delegate: delegateModel.delegate

    // Set this to sort the list view. Must be a function of the form
    // 'function(left, right) { return left < right; }'
    property alias lessThan: delegateModel.lessThan

    property color iconColor: "#00b2ff"
    property color textColor: "black"
    property color hoverBackgroundColor: "#e1f0fb"
    property url nextImageSource

    property string fontFamily

    //--------------------------------------------------------------------------

    signal selected(Item item)
    signal reorder()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("# ListTab items:", container.children.length);
    }

    //--------------------------------------------------------------------------

    onReorder: {
        delegateModel.items.setGroups(0, delegateModel.items.count, "unsorted")
    }

    //--------------------------------------------------------------------------

    ScrollView {
        anchors.fill: parent

        ListView {
            id: listTabViewListView

            clip: true
            boundsBehavior: Flickable.StopAtBounds

            model: delegateModel
        }
    }

    // -------------------------------------------------------------------------

    DelegateModel {
        id: delegateModel

        property var lessThan

        model: container.children

        items.includeByDefault: false

        groups: VisualDataGroup {
            id: unsortedItems
            name: "unsorted"

            includeByDefault: true
            onChanged: {
                if (lessThan && lessThan instanceof Function) {
                    // sort list view according to function 'lessThan(left, right)'
                    delegateModel.sort();
                } else {
                    // do not sort
                    setGroups(0, count, "items");
                }
            }
        }

        function sort() {
            while (unsortedItems.count > 0) {
                var item = unsortedItems.get(0);
                var index = insertPosition(item);

                item.groups = "items";
                items.move(item.itemsIndex, index);
            }
        }

        function insertPosition(item) {
            var lower = 0;
            var upper = items.count;
            while (lower < upper) {
                var middle = Math.floor(lower + (upper - lower) / 2);
                var result = lessThan(item.model, items.get(middle).model);
                if (result) {
                    upper = middle;
                } else {
                    lower = middle + 1;
                }
            }
            return lower;
        }
    }

    //--------------------------------------------------------------------------

    Item {
        id: container
    }

    //--------------------------------------------------------------------------
}
