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
    
    //--------------------------------------------------------------------------

    property alias addInsFolder: addInsFolder
    property alias addInsPage: addInsPage
    property alias servicesManager: servicesManager
    property alias services: servicesManager.services

    //--------------------------------------------------------------------------

    function initialize() {
        
        var importPath = app.folder.filePath("Extensibility");
        
        console.log("Initializing add-ins importPath:", importPath);
        
        AppFramework.addImportPath(importPath);
        
        frameworkInitializer.active = true;

        servicesManager.enabled = true;
        servicesManager.initialize();
    }

    //--------------------------------------------------------------------------

    function start() {
        
        console.log("application.arguments:", JSON.stringify(Qt.application.arguments));
        
        var autoStartAddIn;
        
        for (var i = 1; i < Qt.application.arguments.length; i++) {
            var arg = Qt.application.arguments[i];
            
            switch (arg) {
            case "--addin":
                autoStartAddIn = Qt.application.arguments[++i];
                break;
            }
        }
        
        var count = addInsFolder.update();
        
        if (count || autoStartAddIn) {
//            if (!autoStartAddIn) {
//                autoStartAddIn = settings.value("autoStartAddIn", "");
//            }
            
            console.log("autoStartAddIn:", JSON.stringify(autoStartAddIn));
            var fileInfo = addInsFolder.fileInfo(autoStartAddIn);
            if (autoStartAddIn > "" && fileInfo.exists) {
                startAddIn(fileInfo.filePath);
            } else {
                mainStackView.pushAddInsPage();
            }
        } else {
            mainStackView.pushSurveysGalleryPage();
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        id: frameworkInitializer

        active: false
        source: "AddInFrameworkInitializer.qml"

        onLoaded: {
            item.initialize(app);
            active = false;
            start();
        }
    }

    //--------------------------------------------------------------------------

    AddInsFolder {
        id: addInsFolder

        path: "~/ArcGIS/My Survey Add-Ins"
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInsPage

        MainPage {
            onAddInSelected: {
                if (addInItem.itemId === -1) {
                    mainStackView.pushSurveysGalleryPage();
                } else {
                    startAddIn(addInItem.path);
                }
            }

            onSelected: {
                var count = surveysDatabase.surveyCount(surveyPath);


                if (pressAndHold) {
                    var surveyViewPage = {
                        item: surveyView,
                        properties: {
                            surveyPath: surveyPath,
                            rowid: null,
                            parameters: parameters
                        }
                    }

                    mainStackView.push(surveyViewPage);
                    //                    mainStackView.push([
                    //                                           surveyInfoPage,
                    //                                           surveyViewPage
                    //                                       ]);
                } else {
                    var surveyInfoPage = {
                        item: surveyPage,
                        properties: {
                            surveyPath: surveyPath
                        }
                    };

                    mainStackView.push(surveyInfoPage);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: addInPage

        AddInPage {
            portal: app.portal
        }
    }

    //--------------------------------------------------------------------------

    function startAddIn(path) {
        console.log("Starting addIn:", path);

        mainStackView.push(addInPage,
                           {
                               addInPath: path
                           });
    }

    //--------------------------------------------------------------------------

    AddInServicesManager {
        id: servicesManager

        addInsFolder: addInsFolder
    }

    //--------------------------------------------------------------------------
}
