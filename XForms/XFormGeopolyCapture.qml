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
import ArcGIS.AppFramework.Networking 1.0

import "XForm.js" as JS
import "MapControls"
import "MapDraw"

Rectangle {
    id: geopolyCapture

    property var formElement
    property bool readOnly: false

    property alias map: map
    property XFormMapSettings mapSettings: xform.mapSettings
    property alias positionSourceManager: positionSourceConnection.positionSourceManager

    property bool editingCoords: false

    readonly property bool isEditValid: true

    property color accentColor: xform.style.titleBackgroundColor
    property color barTextColor: xform.style.titleTextColor
    property color barBackgroundColor: accentColor //AppFramework.alphaColor(accentColor, 0.9)
    property real coordinatePointSize: 12 * xform.style.textScaleFactor
    property real locationZoomLevel: 16
    property bool singleLineLatLon: true

    property int buttonHeight: xform.style.buttonSize

    property bool isOnline: Networking.isOnline

    property string forwardGeocodeErrorText: ""

    property bool debug: false

    property var locationCoordinate: QtPositioning.coordinate()

    readonly property alias isEmpty: mapDraw.isEmpty

    property bool enableGeocoder: true

    //--------------------------------------------------------------------------

    property bool isPolygon
    property var mapObject

    //--------------------------------------------------------------------------

    property alias lineColor: mapDraw.lineColor
    property alias lineWidth: mapDraw.lineWidth
    property alias fillColor: mapDraw.fillColor

    //--------------------------------------------------------------------------

    signal accepted
    signal rejected

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        app.settings.setValue("enableGeocoder", true); // temporary

        if (debug) {
            console.log(zoomLevel, JSON.stringify(supportedMapTypes, undefined, 2));
        }

        /*
        if (isEditValid) {
            map.zoomLevel = previewMap.zoomLevel;

            if (map.zoomLevel < map.positionZoomLevel) {
                map.zoomLevel = map.positionZoomLevel;
            }
        }
        else {
            if (debug) {
                console.log("Default map location:", mapSettings.latitude, mapSettings.longitude);
            }

            map.zoomLevel = mapSettings.defaultPreviewZoomLevel;
            map.center = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);

            //            map.positionMode = map.positionModeAutopan;
            positionSourceConnection.start();
        }
        */

        map.addMapTypeMenuItems(mapMenu);

        mapSettings.selectMapType(map);

        console.log("isPolygon:", isPolygon);
        mapDraw.setPath(mapObject.path);
        mapDraw.setMode(MapDraw.Mode.View);

        var isEmpty = mapObject.path.length <= 0;

        if (isEmpty) {
            map.zoomLevel = mapSettings.defaultPreviewZoomLevel;
            map.center = QtPositioning.coordinate(mapSettings.latitude, mapSettings.longitude);

            map.positionMode = map.positionModeAutopan;
        } else {
            map.positionMode = map.positionModeOn;
        }

        positionSourceConnection.start();
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: header

        anchors {
            fill: headerLayout
            margins: -headerLayout.anchors.margins
        }

        color: barBackgroundColor //"#80000000"
    }

    ColumnLayout {
        id: headerLayout

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        spacing: 0

        ColumnLayout {
            id: columnLayout

            Layout.fillWidth: true
            Layout.margins: 2 * AppFramework.displayScaleFactor

            RowLayout {
                Layout.fillWidth: true

                XFormImageButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    source: "images/back.png"
                    color: xform.style.titleTextColor

                    onClicked: {
                        rejected();
                        geopolyCapture.parent.pop();
                    }
                }

                Item {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    visible: locationSensorButton.visible
                }

                XFormText {
                    id: labelText

                    Layout.fillWidth: true

                    text: textValue(formElement.label, "", "long")
                    font {
                        pointSize: xform.style.titlePointSize
                        family: xform.style.titleFontFamily
                    }
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: barTextColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    fontSizeMode: Text.HorizontalFit
                    elide: Text.ElideRight
                }

                XFormLocationSensorButton {
                    id: locationSensorButton

                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    positionSourceManager: geopolyCapture.positionSourceManager
                }

                XFormMenuButton {
                    Layout.fillHeight: true
                    Layout.preferredHeight: buttonHeight
                    Layout.preferredWidth: buttonHeight

                    menuPanel: mapMenuPanel
                }
            }

            XFormText {
                Layout.fillWidth: true

                text: textValue(formElement.hint, "", "long")
                visible: text > ""
                font {
                    pointSize: 12
                }
                horizontalAlignment: Text.AlignHCenter
                color: barTextColor
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor

            visible: enableGeocoder
            spacing: 5 * AppFramework.displayScaleFactor

            GeocoderSearch {
                id: geocoderSearch

                Layout.fillWidth: true

                parseOptions: geopointCapture.parseOptions
                map: geopolyCapture.map
                referenceCoordinate: map.center
                fontFamily: xform.style.fontFamily

                onMapCoordinate: {

                    if (!coordinateInfo.coordinate.isValid) {
                        return;
                    }

                    panTo(coordinateInfo.coordinate);
                }

                onLocationClicked: {
                    // zoomToLocation(location);
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    panTo(location.coordinate);
                    if (currentIndex == index) {
                        selectLocation(location);
                        locationCommitted = true;
                    }
                    else {
                        currentIndex = index;
                    }
                }

                onCommitLocation: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    currentIndex == index;
                    selectLocation(location);
                    locationCommitted = true;
                }

                onLocationDoubleClicked: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    selectLocation(location);
                }

                onLocationPressAndHold: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    selectLocation(location);
                }

                onLocationIndicatorClicked: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    zoomToLocation(location);
                    selectLocation(location);
                }

                onReverseGeocodeSuccess: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    if (typeof editLocation === "boolean") {
                    }
                }

                onResultsReturned: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                    if (resultCount > 0) {
                        inputError = false;
                        forwardGeocodeErrorText = "";
                        return;
                    }
                    inputError = true;
                }

                onGeocoderError: {
                    forwardGeocodeErrorText = error;
                }

                onReverseGeocodeError: {
                    //                    reverseGeocodeErrorText = error;
                }

                onTextChanged: {
                    inputError = false;
                    forwardGeocodeErrorText = "";
                    if (text < "" && editingCoords) {
                        editingCoords = false;
                    }
                }

                onCleared: {
                    if (editingCoords) {
                        editingCoords = false;
                    }
                }
            }
        }

        Text {
            id: errorText

            Layout.fillWidth: true
            Layout.margins: 5 * AppFramework.displayScaleFactor

            visible: text > "" && !geocoderSearch.busy
            wrapMode: Text.WrapAnywhere
            horizontalAlignment: Text.AlignHCenter
            text: forwardGeocodeErrorText

            color: barTextColor
            font {
                bold: true
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormMap {
        id: map

        property real positionZoomLevel: xform.mapSettings.positionZoomLevel

        anchors {
            left: parent.left
            right: parent.right
            top: header.bottom
            bottom: footer.top
        }

        positionSourceConnection: positionSourceConnection

        gesture {
            enabled: true
        }

        mapSettings: parent.mapSettings

        mapControls.onHomeRequested: {
            mapDraw.zoomAll();
        }

        MapDraw {
            id: mapDraw

            isPolygon: geopolyCapture.isPolygon

            onEditVertex: {
                editCoordinate(index, coordinate, qsTr("Editing vertex: %1").arg(index + 1));
            }
        }

        GeocoderItemView {
            search: geocoderSearch

            onClicked: {
                geocoderSearch.showLocation(index, true);
                zoomToLocation(location);
            }
        }

        MapCrosshairs {
            visible: mapDraw.panZoom || geocoderSearch.hasLocations || mapDraw.isMovingVertex
        }
    }

    //--------------------------------------------------------------------------

    Rectangle {
        id: footer

        anchors {
            fill: footerRow
            margins: -footerRow.anchors.margins
        }

        color: barBackgroundColor
        visible: footerRow.visible
    }

    RowLayout {
        id: footerRow

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 15 * AppFramework.displayScaleFactor

        width: parent.width - anchors.margins

        XFormToolButton {
            id: infoButton

            Layout.fillHeight: true
            Layout.preferredHeight: buttonHeight
            Layout.preferredWidth: buttonHeight
            Layout.alignment: Qt.AlignHCenter

            source: "images/information.png"
            color: xform.style.titleTextColor

            visible: !mapDraw.isEmpty && mapDraw.mode === MapDraw.Mode.View

            onClicked: {
                showInfoPage();
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
            Layout.topMargin: 9 * AppFramework.displayScaleFactor
            Layout.bottomMargin: Layout.topMargin
            color: barTextColor
            opacity: 0.3
            visible: infoButton.visible && !readOnly
        }

//        Item {
//            Layout.fillHeight: true
//            Layout.fillWidth: true

//            visible: readOnly
//        }

        RowLayout {

            Layout.fillHeight: true
            Layout.fillWidth: true

            spacing: 15 * AppFramework.displayScaleFactor
            visible: !readOnly

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/line-sketch.png"
                color: xform.style.titleTextColor

                visible: !isPolygon && (mapDraw.mode === MapDraw.Mode.View || mapDraw.captureType === MapDraw.CaptureType.SketchLine)
                checked: mapDraw.captureType === MapDraw.CaptureType.SketchLine

                onClicked: {
                    if (mapDraw.mode === MapDraw.Mode.Capture) {
                        mapDraw.setMode(MapDraw.Mode.View);
                        mapDraw.undo();
                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.SketchLine);
                    }

                    if (isEmpty) {
                        startDraw();
                    } else {
                        var panel = confirmPanel.createObject(app, {
                                                                  title: qsTr("Confirm Line Sketch"),
                                                                  icon: "images/line-sketch.png",
                                                                  question: qsTr("Are you sure you want to re-sketch the line?"),
                                                                  informativeText: qsTr("This action will replace the existing line.")
                                                              });

                        panel.show(startDraw, undefined);
                    }
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/line-segmented.png"
                color: xform.style.titleTextColor

                visible: !isPolygon && (mapDraw.mode === MapDraw.Mode.View || mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line)
                checked: !mapDraw.panZoom && !isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line

                onClicked: {
                    if (mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line) {
                        mapDraw.panZoom = !mapDraw.panZoom;

                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.Line);
                    }

                    if (isEmpty) {
                        startDraw();
                    } else {
                        var panel = confirmPanel.createObject(app, {
                                                                  title: qsTr("Confirm Line Drawing"),
                                                                  icon: "images/line-segmented.png",
                                                                  question: qsTr("Are you sure you want to re-draw the line?"),
                                                                  informativeText: qsTr("This action will replace the existing line.")
                                                              });

                        panel.show(startDraw, undefined);
                    }
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/polygon-sketch.png"
                color: xform.style.titleTextColor

                visible: isPolygon && (mapDraw.mode === MapDraw.Mode.View || mapDraw.captureType === MapDraw.CaptureType.SketchPolygon)
                checked: mapDraw.captureType === MapDraw.CaptureType.SketchPolygon

                onClicked: {
                    if (mapDraw.mode === MapDraw.Mode.Capture) {
                        mapDraw.setMode(MapDraw.Mode.View);
                        mapDraw.undo();
                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.SketchPolygon);
                    }

                    if (isEmpty) {
                        startDraw();
                    } else {
                        var panel = confirmPanel.createObject(app, {
                                                                  title: qsTr("Confirm Area Sketch"),
                                                                  icon: "images/polygon-sketch.png",
                                                                  question: qsTr("Are you sure you want to re-sketch the area?"),
                                                                  informativeText: qsTr("This action will replace the existing area.")
                                                              });

                        panel.show(startDraw, undefined);
                    }
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/polygon-segmented.png"
                color: xform.style.titleTextColor

                visible: isPolygon && (mapDraw.mode === MapDraw.Mode.View || mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon)
                checked: !mapDraw.panZoom && isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon

                onClicked: {
                    if (mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon) {
                        mapDraw.panZoom = !mapDraw.panZoom;

                        return;
                    }

                    function startDraw() {
                        mapDraw.clear();
                        mapDraw.setMode(MapDraw.Mode.Capture, MapDraw.CaptureType.Polygon);
                    }

                    if (isEmpty) {
                        startDraw();
                    } else {
                        var panel = confirmPanel.createObject(app, {
                                                                  title: qsTr("Confirm Area Drawing"),
                                                                  icon: "images/polygon-segmented.png",
                                                                  question: qsTr("Are you sure you want to re-draw the area?"),
                                                                  informativeText: qsTr("This action will replace the existing area.")
                                                              });

                        panel.show(startDraw, undefined);
                    }
                }
            }

            XFormToolButton {
                id: panZoomButton

                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/panZoom.png"
                color: xform.style.titleTextColor

                visible: mapDraw.mode === MapDraw.Mode.Capture && !mapDraw.isSketchingCaptureType
                checkable: true
                checked: mapDraw.panZoom

                onClicked: {
                    mapDraw.panZoom = !mapDraw.panZoom;
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                Layout.topMargin: 9 * AppFramework.displayScaleFactor
                Layout.bottomMargin: Layout.topMargin
                color: barTextColor
                opacity: 0.3
                visible: mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/vertex-add-location.png"
                color: xform.style.titleTextColor

                visible: mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType && positionSourceConnection.active
                enabled: locationCoordinate && locationCoordinate.isValid

                onClicked: {
                    mapDraw.addVertex(locationCoordinate);
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/vertex-add.png"
                color: xform.style.titleTextColor

                visible: mapDraw.panZoom && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType

                onClicked: {
                    mapDraw.addVertex(map.center);
                }

                onPressAndHold: {
                    editCoordinate(-1, map.center, qsTr("Add vertex"));
                }
            }

            /*
        XFormToolButton {
            Layout.fillHeight: true
            Layout.preferredHeight: buttonHeight
            Layout.preferredWidth: buttonHeight
            Layout.alignment: Qt.AlignRight

            source: "images/vertex-add.png"
            color: xform.style.titleTextColor

            visible: mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType

            onClicked: {
                editCoordinate(-1, map.center, qsTr("Add vertex"));
            }
        }
*/

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                Layout.topMargin: 9 * AppFramework.displayScaleFactor
                Layout.bottomMargin: Layout.topMargin
                color: barTextColor
                opacity: 0.3
                visible: vertexEditButton.visible && mapDraw.mode === MapDraw.Mode.View
            }

            XFormToolButton {
                id: vertexEditButton

                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/vertex-edit.png"
                color: xform.style.titleTextColor

                visible: mapDraw.canEdit && mapDraw.mode === MapDraw.Mode.View || mapDraw.mode === MapDraw.Mode.Edit
                checked: mapDraw.mode === MapDraw.Mode.Edit && !mapDraw.isMovingVertex

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.Edit);
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/vertex-move.png"
                color: xform.style.titleTextColor

                visible: mapDraw.isMovingVertex
                checked: mapDraw.isMovingVertex

                onClicked: {
                    mapDraw.endVertexMove();
                }
            }


            Item {
                Layout.fillWidth: true
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/undo.png"
                color: xform.style.titleTextColor

                visible: mapDraw.canUndo || mapDraw.isSketchingCaptureType

                onClicked: {
                    if (mapDraw.isMovingVertex) {
                        mapDraw.endVertexMove(true);
                        return;
                    }

                    mapDraw.undo();
                    if (mapDraw.isSketchingCaptureType) {
                        mapDraw.setMode(MapDraw.Mode.View);
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                Layout.topMargin: 9 * AppFramework.displayScaleFactor
                Layout.bottomMargin: Layout.topMargin

                color: barTextColor
                opacity: 0.3
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/line-segmented-ok.png"
                color: xform.style.titleTextColor

                visible: !isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Line

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/polygon-segmented-ok.png"
                color: xform.style.titleTextColor

                visible: isPolygon && mapDraw.mode === MapDraw.Mode.Capture && mapDraw.captureType === MapDraw.CaptureType.Polygon

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                }
            }

            XFormToolButton {
                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight

                source: "images/vertex-edit-ok.png"
                color: xform.style.titleTextColor

                visible: mapDraw.mode === MapDraw.Mode.Edit

                onClicked: {
                    mapDraw.setMode(MapDraw.Mode.View);
                }
            }

            XFormToolButton {
                id: submitButton

                Layout.fillHeight: true
                Layout.preferredHeight: buttonHeight
                Layout.preferredWidth: buttonHeight
                Layout.alignment: Qt.AlignRight

                source: "images/ok_button.png"
                color: xform.style.titleTextColor
                enabled: isEditValid
                visible: isEditValid && mapDraw.mode === MapDraw.Mode.View

                onClicked: {
                    forceActiveFocus();
                    positionSourceConnection.stop();
                    mapObject = mapDraw.mapPoly;
                    accepted();
                    geopolyCapture.parent.pop();
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormMenuPanel {
        id: mapMenuPanel

        textColor: xform.style.titleTextColor
        backgroundColor: xform.style.titleBackgroundColor
        fontFamily: xform.style.menuFontFamily

        title: qsTr("Map Types")
        menu: Menu {
            id: mapMenu
        }
    }

    //--------------------------------------------------------------------------

    XFormPositionSourceConnection {
        id: positionSourceConnection

        listener: "XFormGeopointCapture"

        onNewPosition: {
            if (position.latitudeValid & position.longitudeValid) {
                if (map.zoomLevel < map.positionZoomLevel && map.positionMode == map.positionModeAutopan) {
                    map.zoomLevel = map.positionZoomLevel;
                }

                locationCoordinate = position.coordinate;
            }
        }

        onActiveChanged: {
            locationCoordinate = QtPositioning.coordinate();
        }
    }

    //--------------------------------------------------------------------------

    function selectLocation(location) {
        if (!location.coordinate.isValid) {
            return;
        }

        geocoderSearch.text = "";//location.displayAddress;
        geocoderSearch.reset();

        if (mapDraw.mode === MapDraw.Mode.Capture && mapDraw.isSegmentedCaptureType) {
            mapDraw.addVertex(location.coordinate);
        }
    }

    //--------------------------------------------------------------------------

    function zoomToLocation(location) {
        map.center = location.coordinate;
    }
    //--------------------------------------------------------------------------

    function panTo(coord) {

        if (positionSourceConnection.active && map.positionMode === map.positionModeAutopan) {
            map.positionMode = map.positionModeOn;
        }

        map.center = coord;
    }

    //--------------------------------------------------------------------------

    function editCoordinate(index, coordinate, title, subTitle) {
        forceActiveFocus();
        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: geopointCapture,
                                        properties: {
                                            title: title,
                                            subTitle: subTitle || "",
                                            editLatitude: coordinate.latitude,
                                            editLongitude: coordinate.longitude,
                                            mapSettings: mapSettings,
                                            editIndex: index
                                        }
                                    });

    }

    //--------------------------------------------------------------------------

    Component {
        id: geopointCapture

        XFormGeopointCapture {
            id: _geopointCapture

            property int editIndex

            positionSourceManager: positionSourceConnection.positionSourceManager
            map.plugin: previewMap.plugin
            markerImage: "images/pin-4.png"

            onAccepted: {
                if (_geopointCapture.changeReason === 1) {
                    var coordinate = QtPositioning.coordinate(editLatitude, editLongitude);

                    console.log("edited coordinate:", JSON.stringify(coordinate, undefined, 2));

                    if (editIndex >= 0) {
                        mapDraw.replaceVertex(editIndex, coordinate);
                    } else {
                        mapDraw.addVertex(coordinate);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            iconColor: xform.style.deleteIconColor
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: infoPage

        XFormGeopolyInfoPage {
        }
    }

    //--------------------------------------------------------------------------

    function showInfoPage() {
        forceActiveFocus();
        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: infoPage,
                                        properties: {
                                            title: labelText.text,
                                            isPolygon: isPolygon,
                                            coordinates: mapDraw.mapPoly.path
                                        }
                                    });

    }

    //--------------------------------------------------------------------------
}
