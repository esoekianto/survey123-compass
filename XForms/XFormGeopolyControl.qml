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

import QtQml 2.11
import QtQuick 2.9
import QtQuick.Layouts 1.3
import QtLocation 5.11
import QtPositioning 5.3

import ArcGIS.AppFramework 1.0

import "XForm.js" as JS
import "XFormGeometry.js" as Geometry

Item {
    id: geopoly

    property XFormData formData

    property var formElement

    property XFormBinding binding
    property bool isPolygon: binding.type === "geoshape"
    readonly property var mapPoly: isPolygon ? mapPolygon : mapPolyline

    property XFormMapSettings mapSettings: xform.mapSettings
    property int previewZoomLevel: mapSettings.previewZoomLevel

    readonly property var appearance: formElement ? formElement["@appearance"] : null;
    readonly property bool readOnly: binding.isReadOnly
    readonly property double accuracyThreshold: Number(formElement["@accuracyThreshold"])

    property var calculatedValue
    property var currentValue
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedValue, currentValue)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool isOnline: AppFramework.network.isOnline

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property bool isValid: false

    property int buttonSize: 25 * AppFramework.displayScaleFactor * xform.style.textScaleFactor

    property bool debug: true

    //--------------------------------------------------------------------------
    // TODO: Move to style

    property color textColor: "#00b2ff"
    property color lineColor: "#00b2ff"
    property real lineWidth: 4 * AppFramework.displayScaleFactor
    property color fillColor: "#3000b2ff"
    property color vertexFillColor: "red"
    property color vertexOutlineColor: "white"
    property real vertexOutlineWidth: 1 * AppFramework.displayScaleFactor
    property real vertexRadius: 10

    property bool showVertices: false

    //--------------------------------------------------------------------------

    property string symbolDefinition
    property var symbolExpressionInstance

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    height: childrenRect.height

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        mapSettings.selectMapType(previewMap);

        var parameters = JS.parseParameters(appearance);
        if (debug) {
            console.log(logCategory, "parameters:", JSON.stringify(parameters, undefined, 2));
        }

        setSymbol(parameters.symbol);
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(geopoly, true)
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(binding.element);
        } else {
            isValid = true;
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== binding.element && changeReason !== 1) {
            if (debug) {
                console.log("onCalculatedValueChanged:", JSON.stringify(calculatedValue, undefined, 2));
            }

            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
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
            Layout.preferredHeight: (previewMap.hasMaps ? 150 : 50) * AppFramework.displayScaleFactor

            color: "lightgrey"
            border {
                width: 1
                color: "#40000000"
            }

            Item {
                anchors {
                    fill: parent
                    margins: 1 * AppFramework.displayScaleFactor
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
                        enabled: false//isValid
                    }

                    onCopyrightLinkActivated: Qt.openUrlExternally(link)

                    onActiveMapTypeChanged: { // Force update of min/max zoom levels
                        minimumZoomLevel = -1;
                        maximumZoomLevel = 9999;
                    }

                    center {
                        latitude: mapSettings.latitude
                        longitude : mapSettings.longitude
                    }


                    MapItemView {
                        id: verticesView

                        model: showVertices ? mapPoly.path : null

                        delegate: MapCircle {
                            center {
                                latitude: verticesView.model[index].latitude
                                longitude: verticesView.model[index].longitude
                            }

                            radius: vertexRadius
                            color: vertexFillColor
                            border {
                                color: vertexOutlineColor
                                width: vertexOutlineWidth
                            }
                        }
                    }

                    MapPolyline {
                        id: mapPolyline

                        visible: false

                        line {
                            color: lineColor
                            width: lineWidth
                        }
                    }

                    MapPolygon {
                        id: mapPolygon

                        visible: false
                        color: fillColor

                        border {
                            color: lineColor
                            width: lineWidth
                        }
                    }
                }

                Text {
                    anchors {
                        fill: parent
                        margins: 10
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

                Text {
                    id: pressText

                    anchors {
                        fill: parent
                        margins: 10 * AppFramework.displayScaleFactor
                    }

                    visible: !isValid && !readOnly && previewMap.hasMaps

                    text: qsTr("Press to capture")
                    color: textColor
                    font {
                        bold: true
                        pointSize: 15
                        family: xform.style.fontFamily
                    }

                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                MouseArea {
                    anchors.fill: parent

                    enabled: previewMap.hasMaps && ((isValid && readOnly) || !readOnly)

                    onWheel: {
                    }

                    onClicked: {
                        Qt.inputMethod.hide();

                        xform.popoverStackView.push({
                                                        item: geopolyCapture,
                                                        properties: {
                                                        }
                                                    });
                    }

                    onPressAndHold: {
                        showVertices = !showVertices;
                    }
                }
            }
        }

        Loader {
            id: calculateButtonLoader

            Layout.preferredWidth: buttonSize
            Layout.preferredHeight: buttonSize

            sourceComponent: calculateButtonComponent
            active: false
            visible: showCalculate && active
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculateButtonComponent

        XFormImageButton {
            source: "images/refresh_update.png"
            color: "transparent"

            onClicked: {
                changeReason = 0;
                formData.triggerCalculate(binding.element);
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: geopolyCapture

        XFormGeopolyCapture {
            id: _geopolyCapture

            formElement: geopoly.formElement
            readOnly: geopoly.readOnly
            positionSourceManager: positionSourceConnection.positionSourceManager
            map.plugin: previewMap.plugin
            isPolygon: geopoly.isPolygon
            mapObject: mapPoly
            lineColor: geopoly.lineColor
            lineWidth: geopoly.lineWidth
            fillColor: geopoly.fillColor

            onAccepted: {
                setValue(mapObject.path, 1);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {

        if (debug) {
            console.log(logCategory, arguments.callee.name,"typeof:", typeof value, "isArray:", Array.isArray(value), "value:", JSON.stringify(value), "reason:", reason, "nodeset:", binding.nodeset);
        }

        if (typeof value === "string") {
            var o;

            try {
                o = JSON.parse(value);
            } catch (e) {
            }

            if (o && typeof o === "object") {
                value = o;
            }
        }

        var geometryValue;

        if (JS.isEmpty(value)) {
            mapPoly.path = [];
            isValid = false;
        } else if (Array.isArray(value)) {
            if (Geometry.isPointsArray(value, true)) {
                mapPoly.path = Geometry.pointsToPath(value);
            } else {
                mapPoly.path = value;
            }

            zoomAll();
            isValid = mapPoly.path.length > 0
            geometryValue = JS.toEsriGeometry(binding.type, mapPoly.path);
        } else if (typeof value === "object") {
            geometryValue = value;

            mapPoly.path = geometryToPath(geometryValue);
            zoomAll();
            isValid = mapPoly.path.length > 0
        }
        else if (typeof value === "string") {
            var geoshape = JS.parsePoly(value);

            if (!geoshape.isEmpty) {

                mapPoly.path = geoshape.path;

                if (debug) {
                    console.log(logCategory, "mapPoly:", mapPoly, mapPoly.path, "geoshape:", typeof geoshape, AppFramework.typeOf(geoshape, true), JSON.stringify(geoshape));
                }

                isValid = true;
                geometryValue = JS.toEsriGeometry(binding.type, mapPoly.path);
            }
        }
        else {
            console.error(logCategory, arguments.callee.name, "Unexpected value:", JSON.stringify(value));
        }

        if (debug) {
            console.log(logCategory, "geometryValue:", JSON.stringify(geometryValue, undefined, 2));
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && isEqual(geometryValue, currentValue)) {
                if (debug) {
                    console.log("input setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        //        formData.setValue(bindElement, XFormJS.toBindingType(value, bindElement));
        formData.setValue(binding.element, geometryValue);

        zoomAll();
    }

    //--------------------------------------------------------------------------

    function zoomAll() {
        var zoomScale = 1.1;
        var zoomRegion = mapPoly.geoShape.boundingGeoRectangle();

        if (zoomRegion && zoomRegion.isValid && !zoomRegion.isEmpty) {
            if (zoomScale) {
                zoomRegion.width *= zoomScale;
                zoomRegion.height *= zoomScale;
            }

            previewMap.visibleRegion = zoomRegion;
            mapPoly.visible = true;
        }
    }

    //--------------------------------------------------------------------------

    function isEqual(value1, value2) {
        return false;
    }

    //------------------------------------------------------------------------------

    function geometryToPath(geometry) {
        var path = [];

        if (isPolygon && Array.isArray(geometry.rings)) {
            path = Geometry.pointsToPath(geometry.rings[0]);
        }
        else if (!isPolygon && Array.isArray(geometry.paths)) {
            path = Geometry.pointsToPath(geometry.paths[0]);
        }
        else if (Array.isArray(geometry.coordinates)) {
            path = Geometry.pointsToPath(geometry.coordinates[0]);
        }

        return path;
    }

    //--------------------------------------------------------------------------

    function setSymbol(marker) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "marker:", JSON.stringify(marker));
        }

        if (typeof marker !== "string") {
            return;
        }

        marker = marker.trim();

        if (marker.charAt(0) === "/") {
            symbolExpressionInstance = formData.expressionsList.addExpression(
                        marker,
                        binding.nodeset,
                        "marker",
                        true);

            symbolDefinition = symbolExpressionInstance.stringBinding("");
        } else {
            symbolDefinition = marker;
        }
    }

    //--------------------------------------------------------------------------

    onSymbolDefinitionChanged: {
        var symbol;

        try {
            symbol = JSON.parse(symbolDefinition);
        } catch (e) {
        }

        if (debug) {
            console.log(logCategory, "symbolDefinition:", symbolDefinition, symbol);
        }

        if (!symbol) {
            //mapMarker.reset();

            return;
        }

        if (debug) {
            console.log(logCategory, "symbol:", JSON.stringify(symbol, undefined, 2));
        }

        var _lineColor = lineColor;
        var _lineWidth = lineWidth;
        var _fillColor = fillColor;

        if (isPolygon && symbol.type === "esriSFS") {
            _fillColor = JS.toColor(symbol.color, "transparernt");
            if (symbol.outline) {
                _lineColor = JS.toColor(symbol.outline.color, "transparent");
                _lineWidth = JS.toNumber(symbol.outline.width, 0) * AppFramework.displayScaleFactor;
            }
        } else if (!isPolygon && symbol.type === "esriSLS") {
            _lineColor = JS.toColor(symbol.color, "white");
            _lineWidth = JS.toNumber(symbol.width, 0) * AppFramework.displayScaleFactor;
        }


        if (_lineColor > "") {
            lineColor = _lineColor;;
        }

        if (isFinite(_lineWidth)) {
            lineWidth = _lineWidth;
        }

        if (_fillColor > "") {
            fillColor = _fillColor;;
        }
    }

    //--------------------------------------------------------------------------
}
