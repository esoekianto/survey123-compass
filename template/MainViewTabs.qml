/* Copyright 2019 Esri
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
import QtQuick.Controls 2.3
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0

ColumnLayout {
    //--------------------------------------------------------------------------

    property color selectedTabColor: app.titleBarBackgroundColor
    property color selectedTabBarColor: Qt.lighter(app.titleBarBackgroundColor, 1.5)
    property color tabColor: "grey"
    property alias view: tabsView
    property alias currentTab: tabsView.currentItem

    //--------------------------------------------------------------------------

    spacing: 0
    
    //--------------------------------------------------------------------------

    SwipeView {
        id: tabsView
        
        Layout.fillWidth: true
        Layout.fillHeight: true
    }
    
    Rectangle {
        Layout.fillWidth: true
        
        height: 1 * AppFramework.displayScaleFactor
        color: "#18000000"
    }
    
    PageIndicator {
        Layout.alignment: Qt.AlignHCenter
        
        delegate: tabIndicatorComponent
        currentIndex: tabsView.currentIndex
        count: tabsView.count
        
        visible: count > 1
    }

    //--------------------------------------------------------------------------

    Component {
        id: tabIndicatorComponent

        Item {
            id: indicator

            property MainViewTab tab: tabsView.itemAt(index)
            property bool selected: index === tabsView.currentIndex
            property color color: selected ? selectedTabColor : tabColor
            property color barColor: selected ? selectedTabBarColor : tabColor

            width: (showTabTitles ? 70 : 50) * AppFramework.displayScaleFactor
            height: layout.childrenRect.height

            visible: tab.visible

            ColumnLayout {
                id: layout

                width: parent.width
                spacing: showTabTitles ? 2 * AppFramework.displayScaleFactor : 0

                Item {
                    Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                    Layout.preferredHeight: Layout.preferredWidth
                    Layout.alignment: Qt.AlignHCenter

                    Component.onCompleted: {
                        indicatorLoader.active = true;
                    }

                    Loader {
                        id: indicatorLoader

                        anchors.fill: parent

                        sourceComponent: tab.indicator
                        active: false

                        onLoaded: {
                            console.log("Add-in indicator loaded:", item, "tab:", tab.title);

                            if (AppFramework.typeOf(item.iconSource) === "url") {
                                item.iconSource = Qt.binding(function () {
                                    return tab.addIn.iconSource;
                                });
                            }

                            if (typeof item.isCurrentIndicator === "boolean") {
                                item.isCurrentIndicator = Qt.binding(function () {
                                    return indicator.selected;
                                });
                            }

                            if (AppFramework.typeOf(item.currentColor) === "color") {
                                item.currentColor = Qt.binding(function () {
                                    return indicator.color;
                                });
                            }
                        }
                    }
                }

                Text {
                    id: tabText

                    Layout.fillWidth: true

                    visible: showTabTitles
                    text: tab.shortTitle
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    color: indicator.color

                    font {
                        family: app.fontFamily
                        pointSize: 10
                        bold: indicator.selected
                    }
                }
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.bottom
                    topMargin: 2 * AppFramework.displayScaleFactor
                }

                width: showTabTitles ? tabText.paintedWidth : layout.width
                visible: selected
                height: 2 * AppFramework.displayScaleFactor
                color: indicator.barColor
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    tabsView.currentIndex = index;
                }

                onPressAndHold:  {
                    tabsView.currentItem.indicatorPressAndHold();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function clear() {
        while (tabsView.count) {
            var tabItem = tabs.takeItem(tabsView.count - 1);
        }
    }

    //--------------------------------------------------------------------------
}
