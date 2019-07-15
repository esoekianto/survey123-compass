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

import "SurveyHelper.js" as Helper

GalleryDelegate {
    id: galleryDelegate

    //--------------------------------------------------------------------------

    property var surveyItem: galleryView.model.get(index);

    //--------------------------------------------------------------------------

    Rectangle {
        anchors {
            fill: indicatorsRow
            margins: -2
        }
        
        visible: false
        radius: height / 2
        color: "#30000000"
    }
    
    //--------------------------------------------------------------------------

    Row {
        id: indicatorsRow
        anchors {
            right: parent.right
            top: parent.top
            topMargin: 2
        }
        
        spacing: 4 * AppFramework.displayScaleFactor
        
        CountIndicator {
            color: red
            count: surveysDatabase.statusCount(path, surveysDatabase.statusSubmitError, surveysDatabase.changed)
            
            onClicked: {
                indicatorsRow.indicatorClicked(0);
            }
        }
        
        CountIndicator {
            color: cyan
            count: surveysDatabase.statusCount(path, surveysDatabase.statusInbox, surveysDatabase.changed)
            
            onClicked: {
                indicatorsRow.indicatorClicked(3);
            }
        }
        
        CountIndicator {
            color: amber
            count: surveysDatabase.statusCount(path, surveysDatabase.statusDraft, surveysDatabase.changed)
            
            onClicked: {
                indicatorsRow.indicatorClicked(1);
            }
        }
        
        CountIndicator {
            color: green
            count: surveysDatabase.statusCount(path, surveysDatabase.statusComplete, surveysDatabase.changed)
            
            onClicked: {
                indicatorsRow.indicatorClicked(2);
            }
        }
        /*
                CountIndicator {
                    color: blue
                    count: surveysDatabase.statusCount(path, surveysDatabase.statusSubmitted, surveysDatabase.changed)
                }
*/
        function indicatorClicked(indicator) {
            galleryView.currentIndex = index;
            if (surveyItem.survey) {
                selected(app.surveysFolder.filePath(surveyItem.survey), false, indicator, null);
            }
        }
    }
    
    //--------------------------------------------------------------------------

    onClicked: {
        galleryView.currentIndex = index;
        galleryView.clicked();
    }
    
    //--------------------------------------------------------------------------

    onPressAndHold: {
        galleryView.currentIndex = index;
        galleryView.pressAndHold();
    }

    //--------------------------------------------------------------------------
}
