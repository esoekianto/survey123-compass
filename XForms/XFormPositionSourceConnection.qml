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

Item {
    property XFormPositionSourceManager positionSourceManager

    readonly property bool valid: positionSourceManager.valid
    readonly property int wkid: positionSourceManager.wkid
    readonly property string errorString: positionSourceManager.errorString

    property string listener

    property bool stayActiveOnError
    property bool active

    property bool debug: positionSourceManager.debug

    //--------------------------------------------------------------------------

    signal newPosition(var position)

    //--------------------------------------------------------------------------

    Component.onDestruction: {
        stop();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: positionSourceManager

        onNewPosition: {
            if (active) {
                newPosition(position);
            }
        }

        onError: {
             if (active && !stayActiveOnError && errorString > "") {
                console.warn("Position manager error:", errorString, ", listener:", listener);
                stop();
            }
        }
    }

    //--------------------------------------------------------------------------

    function start() {
        if (active) {
            if (debug) {
                console.warn("Connection already active - listener:", listener);
            }
            return;
        }

        if (!valid) {
            console.warn("positionSource not valid");
            return;
        }

        active = true;

        positionSourceManager.listen(listener);
    }

    //--------------------------------------------------------------------------

    function stop() {
        if (!active) {
            if (debug) {
                console.warn("Connection not active - listener:", listener);
            }
            return;
        }

        active = false;

        if (!valid) {
            console.warn("positionSource not valid");
            return;
        }

        positionSourceManager.release(listener);
    }

    //--------------------------------------------------------------------------
}
