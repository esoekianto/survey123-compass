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
    id: _sharedTheme

    //--------------------------------------------------------------------------

    property Portal portal

    property bool enabled: portal && portal.signedIn

    property bool debug: true
    property bool persist: false

    //--------------------------------------------------------------------------

    property var sharedTheme

    // body

    property color defaultBodyBackground: "white"
    property color defaultBodyLink: "#00b2ff"
    property color defaultBodyText: "black"

    property color bodyBackground: defaultBodyBackground
    property color bodyLink: defaultBodyLink
    property color bodyText: defaultBodyText

    // button

    property color defaultButtonBackground: "grey"
    property color defaultButtonText: "black"

    property color buttonBackground: defaultButtonBackground
    property color buttonText: defaultButtonText

    // header

    property color defaultHeaderBackground: "darkgrey"
    property color defaultHeaderText: "white"

    property color headerBackground: defaultHeaderBackground
    property color headerText: defaultHeaderText

    // link

    property url defaultLogoLink
    property url defaultLogoSmall

    property url logoLink: defaultLogoLink
    property url logoSmall: defaultLogoSmall

    //--------------------------------------------------------------------------

    readonly property string kSettingSharedTheme: "sharedTheme"

    readonly property string kGroupBody: "body"
    readonly property string kGroupHeader: "header"
    readonly property string kGroupLogo: "logo"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        update();

        if (!read()) {
            update();
        }
    }

    //--------------------------------------------------------------------------

    onEnabledChanged: {
        update();
    }

    onPortalChanged: {
        update();
    }

    Connections {
        target: portal

        onInfoChanged: {
            update();
        }
    }

    //--------------------------------------------------------------------------

    function reset() {
        console.log("Resetting theme to defaults");

        sharedTheme = undefined;
        getProperties();

        write();
    }

    //--------------------------------------------------------------------------

    function update() {
        if (!enabled ||
                !portal.info ||
                !portal.info.portalProperties ||
                !portal.info.portalProperties.sharedTheme) {
            reset();
            return;
        }

        sharedTheme = portal.info.portalProperties.sharedTheme;

        console.log("sharedTheme:", JSON.stringify(sharedTheme, undefined, 2));

        getProperties(sharedTheme);

        write();
    }

    //--------------------------------------------------------------------------

    function getProperties() {
        bodyBackground = getProperty(sharedTheme, kGroupBody, "background");
        bodyLink = getProperty(sharedTheme, kGroupBody, "link");
        bodyText = getProperty(sharedTheme, kGroupBody, "text");

        buttonBackground = getProperty(sharedTheme, "button", "background");
        buttonText = getProperty(sharedTheme, "button", "text");

        headerBackground = getProperty(sharedTheme, kGroupHeader, "background");
        headerText = getProperty(sharedTheme, kGroupHeader, "text");

        logoLink = getProperty(sharedTheme, kGroupLogo, "link");
        logoSmall = getProperty(sharedTheme, kGroupLogo, "small");
    }

    //--------------------------------------------------------------------------

    function getProperty(properties, group, name, defaultProperties) {

        var value = properties ? (properties[group] || {})[name] : undefined;

        if (value === null || value === undefined) {
            var defaultName = "default" +
                    group.substring(0, 1).toUpperCase() + group.substring(1) +
                    name.substring(0, 1).toUpperCase() + name.substring(1);

            if (debug) {
                console.log("getProperty default:", group + "." + name, "property:", defaultName, "value:", _sharedTheme[defaultName]);
            }

            return Qt.binding(function () { return _sharedTheme[defaultName]; });
        }

        if (debug) {
            console.log("getProperty:", group + "." + name, "value:", value);
        }

        return value;
    }

    //--------------------------------------------------------------------------

    function read() {
        if (!portal || !portal.settings || !persist) {
            return;
        }

        sharedTheme = JSON.parse(portal.settings.value(portal.settingName(kSettingSharedTheme), ""));
    }

    //--------------------------------------------------------------------------

    function write() {
        if (!portal || !portal.settings || !persist) {
            return;
        }

        if (sharedTheme) {
            portal.settings.setValue(portal.settingName(kSettingSharedTheme), JSON.stringify(sharedTheme));
        } else {
            portal.settings.remove(portal.settingName(kSettingSharedTheme));
        }
    }

    //--------------------------------------------------------------------------
}
