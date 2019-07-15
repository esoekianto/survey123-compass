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
import QtQuick.Controls 1.4

import ArcGIS.AppFramework 1.0
import "../Portal"

PageMenu {
    //--------------------------------------------------------------------------

    property Portal portal: app.portal
    property bool showSignIn: true
    property bool showAppSettings: true
    property bool showAppAbout: true
    property Page page

    //--------------------------------------------------------------------------

    MenuItem {
        property bool noColorOverlay: portal.signedIn

        visible: showSignIn && portal.signedIn || AppFramework.network.isOnline
        enabled: visible

        text: portal.signedIn ? qsTr("Sign out %1").arg(portal.user ? portal.user.fullName : "") : qsTr("Sign in")
        iconSource: portal.signedIn ? portal.userThumbnailUrl : "images/user.png"

        onTriggered: {
            if (portal.signedIn) {
                portal.signOut();
            } else {
                portal.signIn(undefined, true);
            }
        }
    }

    //--------------------------------------------------------------------------

    MenuItem {
        visible: showAppSettings

        text: qsTr("Settings")
        iconSource: "images/gear.png"

        onTriggered: {
            page.Stack.view.push(appSettingsPage);
        }
    }

    //--------------------------------------------------------------------------

    MenuItem {
        visible: showAppAbout

        text: qsTr("About")
        iconSource: "images/info.png"

        onTriggered: {
            page.Stack.view.push(appAboutPage);
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: appAboutPage

        AboutPage {
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: appSettingsPage

        SettingsPage {
        }
    }

    //--------------------------------------------------------------------------
}
