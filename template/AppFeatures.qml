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

QtObject {
    property App app
    property Settings settings

    //--------------------------------------------------------------------------

    property int buildType: 0 // 0=Release, 1=Beta, 2=Alpha
    readonly property string buildTypeSuffix: kBuildTypeSuffix[buildType]

    property bool addIns: false
    property bool listCache: false
    property bool accessibility: false
    property bool inlineErrorMessages: false

    readonly property bool beta: addIns
                                 || listCache
                                 || accessibility
                                 || inlineErrorMessages

    //--------------------------------------------------------------------------

    readonly property var kBuildTypeSuffix: ["", "β", "α"]

    readonly property string kPrefix: "features"

    readonly property string kKeyAddIns: "addIns"
    readonly property string kKeyListCache: "listCache"
    readonly property string kKeyAccessibility: "accessibility"
    readonly property string kKeyInlineErrorMessages: "inlineErrorMessages"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var title = app.info.title.toLowerCase();

        if (title.indexOf("beta") >= 0) {
            buildType = 1;
        } else if (title.indexOf("alpha") >= 0) {
            buildType = 2;
        }

        console.log("app buildType:", buildType, buildTypeSuffix);
    }

    //--------------------------------------------------------------------------

    function featureKey(featureKey) {
        return "%1/%2".arg(kPrefix).arg(featureKey);
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log("Reading features configuration");

        addIns = settings.boolValue(featureKey(kKeyAddIns), false);
        listCache = settings.boolValue(featureKey(kKeyListCache), false);
        accessibility = settings.boolValue(featureKey(kKeyAccessibility), false);
        inlineErrorMessages = settings.boolValue(featureKey(kKeyInlineErrorMessages), false);

        log();
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log("Writing features configuration");

        log();

        settings.setValue(featureKey(kKeyAddIns), addIns, false);
        settings.setValue(featureKey(kKeyListCache), listCache, false);
        settings.setValue(featureKey(kKeyAccessibility), accessibility, false);
        settings.setValue(featureKey(kKeyInlineErrorMessages), inlineErrorMessages, false);
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log("App features - beta:", beta);
        console.log("* Add-ins:", addIns);
        console.log("* List cache:", listCache);
        console.log("* Accessibility:", accessibility);
        console.log("* Inline error message:", inlineErrorMessages);
    }

    //--------------------------------------------------------------------------
}

