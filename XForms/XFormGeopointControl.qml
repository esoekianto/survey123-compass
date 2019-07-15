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
import QtQml 2.11
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtLocation 5.9
import QtPositioning 5.8

import ArcGIS.AppFramework 1.0

import "XForm.js" as JS

Item {
    id: control

    property XFormData formData

    property var formElement

    property XFormBinding binding

    property alias isValid: geoposition.isValid

    property XFormMapSettings mapSettings: xform.mapSettings
    property int previewZoomLevel: mapSettings.previewZoomLevel

    readonly property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool readOnly: binding.isReadOnly

    property color accurateFillColor: "#4000B2FF"
    property color accurateBorderColor: "#8000B2FF"
    property color inaccurateFillColor: "#40FF0000"
    property color inaccurateBorderColor: "#A0FF0000"

    property var calculatedValue

    readonly property string coordsFormat: mapSettings.previewCoordinateFormat
    readonly property bool isLatLonFormat: JS.isLatLonFormat(coordsFormat)
    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool isOnline: AppFramework.network.isOnline

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated, 4=Position source

    readonly property bool supportsZ: JS.geometryTypeHasZ(binding.esriFieldType)

    property int averageSeconds: 0
    property int averageTotalCount: 0

    //--------------------------------------------------------------------------

    readonly property int kQualityGood: 0
    readonly property int kQualityWarning: 1
    readonly property int kQualityError: 2

    readonly property var kQualityTextColors: [
        "white",
        "black",
        "white"
    ]

    readonly property var kQualityBackgroundColors: [
        "#008000",
        "#FFBF00",
        "#A80000"
    ]

    //--------------------------------------------------------------------------

    property int qualityStatus: kQualityGood
    property alias qualityMessage: qualityText.text
    readonly property color qualityTextColor: kQualityTextColors[qualityStatus]
    readonly property color qualityBackgroundColor: kQualityBackgroundColors[qualityStatus]

    readonly property alias horizontalAccuracy: geoposition.horizontalAccuracy
    readonly property string accuracyMessgae: qsTr("Coordinates are not within the accuracy threshold of %1 m").arg(accuracyThreshold)
    readonly property double accuracyThreshold: Number(formElement["@accuracyThreshold"])
    readonly property bool isAccurate: accuracyThreshold <= 0
                                       || !isFinite(accuracyThreshold)
                                       || (geoposition.horizontalAccuracyValid ? geoposition.horizontalAccuracy <= accuracyThreshold : true)
    property bool showAccuracy: true

    property var constraint
    property bool constraintOk: true

    readonly property string kAttributeQualityWarning: "esri:warning"
    property var warningExpressionInstance
    property bool warningOk: true
    property string warningMessage: qsTr("Location quality warning")

    //--------------------------------------------------------------------------

    readonly property var kIndicatorFillColors: [
        "#4000B2FF",
        "#40FFBF00",
        "#40FF0000"
    ]

    readonly property var kIndicatorBorderColors: [
        "#8000B2FF",
        "#80FFBF00",
        "#A0FF0000"
    ]

    readonly property color indicatorFillColor: kIndicatorFillColors[qualityStatus]
    readonly property color indicatorBorderColor: kIndicatorBorderColors[qualityStatus]

    //--------------------------------------------------------------------------

    property string symbolDefinition
    property var symbolExpressionInstance

    //--------------------------------------------------------------------------

    property bool debug: false

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    height: childrenRect.height

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (isValid) {
            previewMap.zoomLevel = previewZoomLevel;
        } else {
            previewMap.zoomLevel = 0;
        }

        mapSettings.selectMapType(previewMap);

        var parameters = JS.parseParameters(appearance);
        if (debug) {
            console.log(logCategory, "parameters:", JSON.stringify(parameters, undefined, 2));
        }

        setSymbol(parameters.symbol);

        initializeQuality();
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(control, true)
    }


    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(binding.element);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding.element && changeReason !== 1) {
            if (debug) {
                console.log(logCategory, "onCalculatedValueChanged changeReason:", changeReason, "geopoint:", JSON.stringify(calculatedValue, undefined, 2));
            }

            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    XFormGeoposition {
        id: geoposition

        onChanged: {
            if (debug) {
                console.log(logCategory, "Updating value from geoposition for:", binding.nodeset);
            }

            updateValue();
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: row

        width: parent.width
        //height: parent.height// 100 * AppFramework.displayScaleFactor
        layoutDirection: xform.languageDirection

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: (previewMap.hasMaps ? 100 : 50) * AppFramework.displayScaleFactor + coordsHeader.height

            color: "lightgrey"
            border {
                width: 1
                color: "#40000000"
            }

            Rectangle {
                id: coordsHeader
                anchors {
                    fill: coordsRow
                    margins: -coordsRow.anchors.margins
                }

                visible: coordsRow.visible
                color: qualityBackgroundColor
            }

            RowLayout {
                id: coordsRow

                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 5
                }

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            Layout.fillWidth: true

                            visible: isValid

                            Flow {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignCenter

                                spacing: 5 * AppFramework.displayScaleFactor

                                XFormText {
                                    text: formatCoordinate(geoposition, coordsFormat)
                                    color: qualityTextColor
                                    font.bold: true
                                }

                                XFormText {
                                    visible: geoposition.horizontalAccuracyValid
                                    text: qsTr("± %1 m").arg(JS.round(geoposition.horizontalAccuracy, geoposition.horizontalAccuracy < 1 ? mapSettings.horizontalAccuracyPrecisionHigh : mapSettings.horizontalAccuracyPrecisionLow))
                                    color: qualityTextColor
                                    font.bold: true
                                }

                                Row {
                                    visible: supportsZ && geoposition.altitudeValid
                                    spacing: 3 * AppFramework.displayScaleFactor

                                    XFormText {
                                        text: qsTr("Alt")
                                        color: qualityTextColor
                                    }

                                    XFormText {
                                        text: JS.round(geoposition.altitude, geoposition.verticalAccuracy < 1 ? mapSettings.verticalAccuracyPrecisionHigh : mapSettings.verticalAccuracyPrecisionLow) + "m"
                                        color: qualityTextColor
                                        font.bold: true
                                    }

                                    XFormText {
                                        visible: geoposition.verticalAccuracyValid
                                        text: qsTr("± %1 m").arg(JS.round(geoposition.verticalAccuracy, geoposition.verticalAccuracy < 1 ? mapSettings.verticalAccuracyPrecisionHigh : mapSettings.verticalAccuracyPrecisionLow))
                                        color: qualityTextColor
                                        font.bold: true
                                    }
                                }
                            }

                            XFormText {
                                Layout.fillWidth: true

                                visible: (positionSourceConnection.active && geoposition.averaging) || geoposition.averageCount > 0
                                text: qsTr("Averaged %1 of %2 positions (%3 seconds)").arg(geoposition.averageCount).arg(averageTotalCount).arg(averageSeconds)
                                color: qualityTextColor
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }

                            XFormText {
                                id: qualityText

                                Layout.fillWidth: true

                                visible: qualityStatus > kQualityGood && text > ""
                                color: qualityTextColor
                                font {
                                    bold: true
                                }
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            }
                        }

                        XFormText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter

                            visible: !isValid
                            text: qsTr("No Location")
                            color: qualityTextColor
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }

                        XFormText {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter

                            visible: text > ""
                            text: positionSourceConnection.errorString
                            color: qualityTextColor
                            font {
                                bold: true
                            }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        }
                    }

                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        visible: positionSourceConnection.valid && (!readOnly || !isValid)

                        XFormImageButton {
                            id: positionButton

                            anchors.fill: parent

                            source: positionSourceConnection.active ? "images/position-on.png" : "images/position-off.png"
                            color: qualityTextColor

                            onClicked: {
                                forceActiveFocus();

                                if (positionSourceConnection.active) {
                                    geoposition.averageEnd();
                                    positionSourceConnection.stop();
                                } else {
                                    geoposition.averageClear();
                                    positionSourceConnection.start();
                                }
                            }

                            onPressAndHold: {
                                forceActiveFocus();

                                if (!geoposition.averaging || !positionSourceConnection.active) {
                                    startAverage();
                                }
                                positionSourceConnection.start();
                            }
                        }

                        BusyIndicator {
                            anchors.fill: parent
                            running: positionSourceConnection.active
                        }

                        Timer {
                            interval: 1000
                            running: positionSourceConnection.active && geoposition.averaging
                            repeat: true
                            triggeredOnStart: false

                            onTriggered: {
                                averageSeconds++;
                            }
                        }
                    }

                    Loader {
                        id: calculateButtonLoader

                        Layout.preferredWidth: 30 * AppFramework.displayScaleFactor
                        Layout.preferredHeight: Layout.preferredWidth

                        sourceComponent: calculateButtonComponent
                        active: false
                        visible: (changeReason === 1 || changeReason === 4) && active
                    }
                }
            }

            Item {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: coordsHeader.bottom
                    bottom: parent.bottom
                    margins: 1
                }

                Map {
                    id: previewMap

                    property bool hasMaps: supportedMapTypes.length > 0

                    anchors.fill: parent

                    visible: hasMaps

                    plugin: XFormMapPlugin {
                        settings: mapSettings
                        offline: !isOnline
                    }

                    gesture {
                        enabled: false //isValid
                    }

                    zoomLevel: isValid ? previewZoomLevel : 0
                    center {
                        latitude: geoposition.latitude
                        longitude: geoposition.longitude
                    }

                    //activeMapType: supportedMapTypes[0]

                    /*
                Component.onCompleted: {
                    console.log("previewMap # maps:", previewMap.supportedMapTypes.length, mapSettings.appendMapTypes);

                    for (var i = 0; i < previewMap.supportedMapTypes.length; i++) {
                        var mapType = previewMap.supportedMapTypes[i];
                        console.log("mapType", i, mapType.name, mapType.description);
                    }
                }
                */

                    onCopyrightLinkActivated: Qt.openUrlExternally(link)

                    onActiveMapTypeChanged: { // Force update of min/max zoom levels
                        minimumZoomLevel = -1;
                        maximumZoomLevel = 9999;
                    }

                    MapCircle {
                        visible: showAccuracy && geoposition.horizontalAccuracyValid && geoposition.horizontalAccuracy > 0

                        radius: horizontalAccuracy
                        center: mapMarker.coordinate
                        color: indicatorFillColor
                        border {
                            width: 1
                            color: indicatorBorderColor
                        }
                    }

                    XFormMapMarker {
                        id: mapMarker

                        visible: isValid
                        coordinate {
                            latitude: geoposition.latitude
                            longitude: geoposition.longitude
                        }
                    }
                }

                XFormText {
                    anchors {
                        fill: parent
                        margins: 10 * AppFramework.displayScaleFactor
                    }

                    visible: isValid && !previewMap.hasMaps

                    text: isOnline
                          ? qsTr("Map preview not available")
                          : qsTr("Offline map preview not available")

                    color: "red"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                Rectangle {
                    anchors.fill: parent

                    visible: pressText.visible

                    color: "#A0FFFFFF"
                }

                XFormText {
                    id: pressText

                    anchors {
                        fill: parent
                        margins: 10
                    }

                    visible: !isValid && !readOnly && previewMap.hasMaps

                    text: qsTr("Press to capture location using a map")
                    color: "red"
                    font {
                        bold: true
                        pointSize: 15
                    }

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: !readOnly && previewMap.hasMaps

                    onWheel: {
                    }

                    onClicked: {
                        forceActiveFocus();
                        Qt.inputMethod.hide();
                        xform.popoverStackView.push({
                                                        item: geopointCapture,
                                                        properties: {
                                                            formElement: formElement,
                                                            editLatitude: geoposition.latitude,
                                                            editLongitude: geoposition.longitude,
                                                            editAltitude: geoposition.altitude,
                                                            editHorizontalAccuracy: geoposition.horizontalAccuracy,
                                                            editVerticalAccuracy: geoposition.verticalAccuracy,
                                                            showAltitude: supportsZ,
                                                            mapSettings: mapSettings,
                                                            lastPositionSourceReading: positionSourceConnection.lastPosition
                                                        }
                                                    });
                        positionSourceConnection.stop();
                    }
                }
            }
        }

        XFormPositionSourceConnection {
            id: positionSourceConnection

            property var lastPosition: ({})

            positionSourceManager: xform.positionSourceManager
            listener: binding.nodeset

            onNewPosition: {
                if (control.debug) {
                    console.log(logCategory, "Updating geopoint nodeset:", binding.nodeset, "position:", JSON.stringify(position, undefined, 2));
                }
                lastPosition = position;
                updatePosition(position);
            }
        }

        Component {
            id: geopointCapture

            XFormGeopointCapture {
                id: _geopointCapture
                positionSourceManager: positionSourceConnection.positionSourceManager
                map.plugin: previewMap.plugin

                title: textValue(formElement.label, "", "long")
                subTitle: textValue(formElement.hint, "", "long")
                marker: mapMarker

                onAccepted: {

                    if (control.debug) {
                        console.log(logCategory, "accepted:", changeReason, "control.changeReason:", control.changeReason);
                    }

                    switch (_geopointCapture.changeReason) {

                    case 1:
                        var coordinate = {
                            latitude: editLatitude,
                            longitude: editLongitude,
                            altitude: editAltitude,
                            horizontalAccuracy: editHorizontalAccuracy,
                            verticalAccuracy: editVerticalAccuracy,
                            positionSourceType: 1
                        };

                        if (editLocation && editLocation.displayAddress) {
                            var address = editLocation.displayAddress;
                            address.objectName = undefined;
                            coordinate.displayAddress = address;
                        }

                        if (editLocation && editLocation.attributes) {
                            var attributes = editLocation.attributes;
                            attributes.objectName = undefined;
                            coordinate.attributes = attributes;
                        }

                        if (control.debug) {
                            console.log(logCategory, "edited coordinate:", JSON.stringify(coordinate, undefined, 2));
                        }

                        geoposition.fromObject(coordinate);

                        previewMap.zoomLevel = map.zoomLevel

                        control.changeReason = 1;
                        break;

                    case 0:
                        // User didn't interact with the map control at all.
                        updatePosition(_geopointCapture.lastPositionSourceReading);
                        break;

                    case 4:
                        updatePosition(_geopointCapture.lastPositionSourceReading);
                        break;

                    case 2:
                    case 3:
                        break;
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculateButtonComponent

        Rectangle {
            color: "#80FFFFFF"
            radius: 5 * AppFramework.displayScaleFactor

            XFormImageButton {
                id: calculateButton

                anchors {
                    fill: parent
                    margins: 2 * AppFramework.displayScaleFactor
                }

                source: "images/refresh_update.png"
                color: qualityTextColor

                onClicked: {
                    if (positionSourceConnection.active) {
                        positionSourceConnection.stop();
                    }

                    changeReason = 0;
                    formData.triggerCalculate(binding.element);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function updatePosition(position) {
        if (!position.coordinate) {
            return;
        }

        var isAcceptable = qualityStatus <= kQualityWarning;

        if (debug) {
            console.log(logCategory, "isAcceptable:", isAcceptable, "position:", JSON.stringify(position));
        }

        if (geoposition.averaging) {
            if (isAcceptable) {
                geoposition.averagePosition(position);
            }

            averageTotalCount++;
        } else {
            geoposition.fromPosition(position);

            if (isAcceptable) {
                positionSourceConnection.stop();
            }
        }

        previewMap.zoomLevel = previewZoomLevel;
        changeReason = 4;
    }

    //--------------------------------------------------------------------------

    function updateValue() {
        if (debug) {
            console.log(logCategory, "geoposition updateValue:", JSON.stringify(geoposition.toObject()));
        }

        formData.setValue(binding.element, geoposition.toObject());

        if (previewMap.zoomLevel < previewZoomLevel) {
            previewMap.zoomLevel = previewZoomLevel;
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            changeReason = reason;
        } else {
            changeReason = 2;
        }

        if (debug) {
            console.log(logCategory, "geopoint setValue:", JSON.stringify(value), "reason:", reason, "changeReason:", changeReason, "nodeset:", binding.nodset);
            console.trace();
        }

        if (value === "position" || value === "average") {
            var doAverage = value === "average";

            if (debug) {
                console.log(logCategory, "Activating position source for:", binding.nodeset, "currentValue:", JSON.stringify(geoposition.toObject()));
            }

            geoposition.clear();

            if (doAverage) {
                startAverage();
            }
            positionSourceConnection.start();

            return;
        }

        if (JS.isNullOrUndefined(value)) {
            geoposition.clear();
            return;
        }

        if ((changeReason === 1 || changeReason === 3) && positionSourceConnection.active) {
            console.log(logCategory, arguments.callee.name, "Stopping position source for:", binding.nodeset, "reason:", reason, "changeReason:", changeReason);
            positionSourceConnection.stop();
        }

        var doZoom = false;

        if (typeof value === "object") {
            geoposition.fromObject(value);

            doZoom = true;
        } else if (typeof value === "string") {
            var coordinate = JS.parseGeopoint(value);

            if (coordinate && coordinate.isValid) {
                geoposition.fromObject(coordinate);

                doZoom = true;
            }
        } else {
            geoposition.clear();
        }

        if (doZoom) {
            previewMap.zoomLevel = previewZoomLevel;
        }
    }

    //--------------------------------------------------------------------------

    function startAverage() {
        console.log(logCategory, "startAverage");
        averageTotalCount = 0;
        averageSeconds = 0;
        geoposition.averageBegin();
    }

    //--------------------------------------------------------------------------

    function formatCoordinate(geoposition, coordinateFormat) {
        var coordinate = QtPositioning.coordinate(geoposition.latitude, geoposition.longitude);

        return JS.formatCoordinate(coordinate, coordinateFormat);
    }

    //--------------------------------------------------------------------------

    function initializeQuality() {

        var bindElement = binding.element;

        constraint = formData.createConstraint(this, bindElement);
        if (constraint) {
            if (!(constraint.message > "")) {
                constraint.message = qsTr("Location quality constraint not satisfied");
            }

            constraintOk = constraint.expressionInstance.boolBinding(false);

            console.log(logCategory, "geopoint constraint expression:", constraint.expressionInstance.expression, "message:", constraint.message);
        }

        var expression = formData.getExpression(bindElement, kAttributeQualityWarning);
        if (expression) {
            warningExpressionInstance = formData.expressionsList.addExpression(
                        expression,
                        binding.nodeset,
                        "warning",
                        true);

            var message = bindElement["@" + kAttributeQualityWarning + "_message"];
            if (message > "") {
                warningMessage = message;
            }

            warningOk = warningExpressionInstance.boolBinding(false);

            console.log(logCategory, "geopoint warning expression:", warningExpressionInstance.expression, "message:", warningMessage);
        }
    }

    //--------------------------------------------------------------------------

    onIsValidChanged: {
        updateQuality();
    }

    onIsAccurateChanged: {
        updateQuality();
    }

    onConstraintOkChanged: {
        updateQuality();
    }

    onWarningOkChanged: {
        updateQuality();
    }

    //--------------------------------------------------------------------------

    function updateQuality() {
        if (debug) {
            console.log(logCategory, "updateQuality");

            console.log(logCategory, "isValid:", isValid);
            console.log(logCategory, "isAccurate:", isAccurate, "threshold:", accuracyThreshold, "horizontalAccuracy:", geoposition.horizontalAccuracy, "valid:", geoposition.horizontalAccuracyValid);
            console.log(logCategory, "constraintOk:", constraintOk);
            console.log(logCategory, "warningOk:", warningOk);
        }

        if (!isValid) {
            qualityMessage = "";
            qualityStatus = kQualityError;

            return;
        }

        if (!isAccurate) {
            qualityMessage = accuracyMessgae;
            qualityStatus = kQualityError;

            return;
        }

        if (!constraintOk) {
            qualityMessage = constraint.message;
            qualityStatus = kQualityError;

            return;
        }


        if (!warningOk) {
            qualityMessage = warningMessage;
            qualityStatus = kQualityWarning;

            return;
        }

        qualityMessage = "";
        qualityStatus = kQualityGood;
    }

    //--------------------------------------------------------------------------

    function setSymbol(symbol) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "symbol:", JSON.stringify(symbol));
        }

        if (typeof symbol !== "string") {
            return;
        }

        symbol = symbol.trim();

        if (symbol.charAt(0) === "/") {
            symbolExpressionInstance = formData.expressionsList.addExpression(
                        symbol,
                        binding.nodeset,
                        "symbol",
                        true);

            symbolDefinition = symbolExpressionInstance.stringBinding("");
        } else {
            symbolDefinition = symbol;
        }
    }

    //--------------------------------------------------------------------------

    onSymbolDefinitionChanged: {

        if (debug) {
            console.log(logCategory, "symbolDefinition:", JSON.stringify(symbolDefinition));
        }

        var urlInfo = AppFramework.urlInfo("");
        urlInfo.fromUserInput(symbolDefinition);

        if (debug) {
            console.log(logCategory, "symbol host:", JSON.stringify(urlInfo.host), "queryParameters:", JSON.stringify(urlInfo.queryParameters));
        }

        if (!urlInfo.isValid) {
            console.warn(logCategory, "Invalid url:", urlInfo.url);
            mapMarker.reset();
            return;
        }

        var image = urlInfo.host;
        if (xform.mediaFolder.fileExists(image)) {
            mapMarker.image.source = xform.mediaFolder.fileUrl(image);

            var x = 0.5;
            var y = 1;
            var scale = 1;

            var parameters = urlInfo.queryParameters;

            var keys = Object.keys(parameters);

            keys.forEach(function (key) {
                var value = parameters[key];

                if (debug) {
                    console.log(logCategory, "key:", JSON.stringify(key), "=", JSON.stringify(value));
                }

                switch (key) {
                case "x" :
                    x = Number(value);
                    break;

                case "y" :
                    y = Number(value);
                    break;

                case "scale" :
                    scale = Number(value);
                    break;
                }

            });

            if (isFinite(x)) {
                mapMarker.anchorX = x;
            }

            if (isFinite(y)) {
                mapMarker.anchorY = y;
            }

            if (isFinite(scale)) {
                mapMarker.imageScale = scale;
            }
        } else {
            mapMarker.reset();
        }
    }

    //--------------------------------------------------------------------------
}
