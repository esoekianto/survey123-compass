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
    property real textScaleFactor: 1.0

    property string fontFamily
    property bool boldText: false

    property color backgroundColor: "transparent"
    property color textColor: "black"
    property string backgroundImage
    property int backgroundImageFillMode: Image.PreserveAspectCrop

    property color titleTextColor: "white"
    property color titleBackgroundColor: "#408c31"
    property real titlePointSize: 22
    property string titleFontFamily: fontFamily
    property real titleButtonSize: 35 * AppFramework.displayScaleFactor

    property string menuFontFamily: fontFamily

    property color headerTextColor: "white"
    property color headerBackgroundColor: "darkgrey"

    property real groupLabelPointSize: 18 * textScaleFactor
    property color groupLabelColor: Qt.lighter(textColor, 1.25) // "darkred
    property bool groupLabelBold: true
    property string groupLabelFontFamily: fontFamily

    property real labelPointSize: 16 * textScaleFactor
    property color labelColor: textColor
    property bool labelBold: boldText
    property string labelFontFamily: fontFamily

    property real valuePointSize: 15 * textScaleFactor
    property color valueColor: inputTextColor
    property color valueAltColor: inputAltTextColor
    property bool valueBold: boldText
    property string valueFontFamily: fontFamily

    property real hintPointSize: 12 * textScaleFactor
    property color hintColor: Qt.darker(textColor, 1.25) // "#202020"
    property bool hintBold: boldText
    property string hintFontFamily: fontFamily

    property real guidanceHintPointSize: 13 * textScaleFactor
    property string guidanceHintFontFamily: fontFamily

    property color inputTextColor: "black"
    property color inputAltTextColor: "darkblue"
    property color inputBackgroundColor: "white"
    property color inputErrorTextColor: "red"
    property color inputErrorBackgroundColor: "white"
    property color inputReadOnlyTextColor: "black"
    property color inputReadOnlyBackgroundColor: "#f7f7f7"
    property color inputPlaceholderTextColor:  AppFramework.alphaColor(inputTextColor, 0.4)
    property bool inputBold: boldText
    property real inputPointSize: 15 * textScaleFactor
    property string inputFontFamily: fontFamily
    property color inputBorderColor: "#ddd"
    property color inputActiveBorderColor: "#47b"
    property int multilineTextHeight: 150 * AppFramework.displayScaleFactor
    property color inputCountColor: "#202020"
    property color inputCountWarningColor: "#a00000"

    property color selectTextColor: inputTextColor
    property color selectAltTextColor: inputAltTextColor
    property bool selectBold: boldText
    property real selectPointSize: 15 * textScaleFactor
    property color selectHighlightTextColor: "white"
    property color selectHighlightColor: "#2685fc"
    property string selectFontFamily: fontFamily

    property color signatureBackgroundColor: "white"
    property color signatureBorderColor: "lightgrey"
    property color signaturePenColor: "black"
    property real signaturePenWidth: 3
    property int signatureHeight: 135 * AppFramework.displayScaleFactor

    property int gridColumnWidth: 125 * AppFramework.displayScaleFactor
    property real gridSpacing: 5 * AppFramework.displayScaleFactor

    property int imageButtonSize: 40 * AppFramework.displayScaleFactor * textScaleFactor
    property int playButtonSize: 30 * AppFramework.displayScaleFactor

    property color buttonColor: "#606060"
    property real buttonSize: 35 * AppFramework.displayScaleFactor // Default non-specific button size
    property real buttonTextPointSize: 16

    property color keyColor: "#888"
    property color keyTextColor: "white"
    property color keyBorderColor: "#999"
    property color keyStyleColor: "grey"
    property string keyFontFamily: fontFamily

    property string calendarFontFamily: fontFamily

    property color iconColor: "#666"
    property color deleteIconColor: "#A80000"

    property color requiredColor: "#A80000"

    //--------------------------------------------------------------------------

    readonly property alias implicitText: implicitText
    readonly property alias implicitTextHeight: implicitText.implicitHeight

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        log();
    }

    //--------------------------------------------------------------------------

    Text {
        id: implicitText

        font {
            family: fontFamily
            pointSize: 12 * textScaleFactor
        }
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log("XForm style -");
        console.log("* fontFamily:", fontFamily);
        console.log("* textScaleFactor:", textScaleFactor);
        console.log("* implicitText pointSize:", implicitText.font.pointSize);
        console.log("* implicitTextHeight:", implicitTextHeight);
    }

    //--------------------------------------------------------------------------
}
