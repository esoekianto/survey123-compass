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
    property Settings settings: app.settings

    //--------------------------------------------------------------------------

    // Accessibility

    property bool boldText: false
    property bool plainBackgrounds: true

    // Text

    property string defaultFontFamily: app.info.propertyValue(kKeyFontFamily, fontFamily)
    property string fontFamily: Qt.application.font.family
    property real textScaleFactor: 1

    // Storage

    property string mapLibraryPaths: kDefaultMapLibraryPath

    // Spatial reference

    property int defaultWkid: 4326
    property int wkid: defaultWkid

    // Location

    property bool showActivationModeSettings: false

    property bool discoverBluetooth: true
    property bool discoverBluetoothLE: false
    property bool discoverSerialPort: false

    property string hostname: ""
    property string port: ""

    property string internalPositionSourceName: qsTr("Integrated Provider")

    property string lastUsedDeviceName: ""
    property string lastUsedDeviceJSON: ""
    property var knownDevices: ({})

    property bool locationAlertsVisual: false
    property bool locationAlertsSpeech: false
    property bool locationAlertsVibrate: false

    property int locationMaximumDataAge: 5000
    property int locationMaximumPositionAge: 5000
    property int locationSensorActivationMode: kActivationModeAlways
    property int locationSensorConnectionType: kConnectionTypeInternal
    property int locationAltitudeType: kAltitudeTypeMSL

    property real locationGeoidSeparation: Number.NaN
    property real locationAntennaHeight: Number.NaN

    //--------------------------------------------------------------------------

    // Accessibility

    readonly property string kKeyAccessibilityPrefix: "Accessibility/"
    readonly property string kKeyAccessibilityBoldText: kKeyAccessibilityPrefix + "boldText"
    readonly property string kKeyAccessibilityPlainBackgrounds: kKeyAccessibilityPrefix + "plainBackgrounds"

    // Text

    readonly property string kKeyFontFamily: "fontFamily"
    readonly property string kKeyTextScaleFactor: "textScaleFactor"

    // Storage

    readonly property string kDefaultMapLibraryPath: "~/ArcGIS/My Surveys/Maps"
    readonly property string kKeyMapLibraryPaths: "mapLibraryPaths"

    // Spatial reference

    readonly property string kKeyWkid: "wkid"

    // Location

    readonly property string kInternalPositionSourceName: "IntegratedProvider"
    readonly property string kKeyShowActivationModeSettings: "ShowActivationModeSettings"

    readonly property string kKeyLocationPrefix: "Location/"
    readonly property string kKeyLocationKnownDevices: kKeyLocationPrefix + "knownDevices"
    readonly property string kKeyLocationLastUsedDevice: kKeyLocationPrefix + "lastUsedDevice"
    readonly property string kKeyLocationLastConnectionType: kKeyLocationPrefix + "lastConnectionType"
    readonly property string kKeyLocationDiscoverBluetooth: kKeyLocationPrefix + "discoverBluetooth"
    readonly property string kKeyLocationDiscoverBluetoothLE: kKeyLocationPrefix + "discoverBluetoothLE"
    readonly property string kKeyLocationDiscoverSerialPort: kKeyLocationPrefix + "discoverSerialPort"

    readonly property int kActivationModeAsNeeded: 0
    readonly property int kActivationModeInSurvey: 1
    readonly property int kActivationModeAlways: 2

    readonly property int kConnectionTypeInternal: 0
    readonly property int kConnectionTypeExternal: 1
    readonly property int kConnectionTypeNetwork: 2

    readonly property int kAltitudeTypeMSL: 0
    readonly property int kAltitudeTypeHAE: 1

    //--------------------------------------------------------------------------

    property bool updating

    signal receiverListUpdated()

    //--------------------------------------------------------------------------

    Component.onCompleted: {
    }

    //--------------------------------------------------------------------------

    onFontFamilyChanged: {
        console.log("Font family changed:", fontFamily);
    }

    //--------------------------------------------------------------------------

    onLastUsedDeviceNameChanged: {
        updating = true;

        if (knownDevices && lastUsedDeviceName > "") {
            var receiverSettings = getReceiverSettings(lastUsedDeviceName);

            if (receiverSettings) {
                switch (receiverSettings.connectionType) {
                case kConnectionTypeInternal:
                    lastUsedDeviceJSON = "";
                    hostname = "";
                    port = "";
                    break;
                case kConnectionTypeExternal:
                    lastUsedDeviceJSON = receiverSettings.receiver > "" ? JSON.stringify(receiverSettings.receiver) : "";
                    hostname = "";
                    port = "";
                    break;
                case kConnectionTypeNetwork:
                    lastUsedDeviceJSON = ""
                    hostname = receiverSettings.hostname;
                    port = receiverSettings.port;
                    break;
                default:
                    console.log("Error: unknown connectionType", receiverSettings.connectionType);
                    updating = false;
                    return;
                }

                locationAlertsVisual = receiverSettings.locationAlertsVisual;
                locationAlertsSpeech = receiverSettings.locationAlertsSpeech;
                locationAlertsVibrate = receiverSettings.locationAlertsVibrate;
                locationMaximumDataAge = receiverSettings.locationMaximumDataAge;
                locationMaximumPositionAge = receiverSettings.locationMaximumPositionAge;
                locationSensorActivationMode = receiverSettings.activationMode;
                locationSensorConnectionType = receiverSettings.connectionType;
                locationAltitudeType = receiverSettings.altitudeType;
                locationGeoidSeparation = receiverSettings.geoidSeparation ? receiverSettings.geoidSeparation : Number.NaN;
                locationAntennaHeight = receiverSettings.antennaHeight ? receiverSettings.antennaHeight : Number.NaN;
            }
        }

        updating = false;
    }

    //--------------------------------------------------------------------------

    onLocationAlertsVisualChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].locationAlertsVisual = locationAlertsVisual;
        }
    }

    onLocationAlertsSpeechChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].locationAlertsSpeech = locationAlertsSpeech;
        }
    }

    onLocationAlertsVibrateChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].locationAlertsVibrate = locationAlertsVibrate;
        }
    }

    onLocationMaximumDataAgeChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].locationMaximumDataAge = locationMaximumDataAge;
        }
    }

    onLocationMaximumPositionAgeChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].locationMaximumPositionAge = locationMaximumPositionAge;
        }
    }

    onLocationSensorActivationModeChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].activationMode = locationSensorActivationMode;
        }
    }

    onLocationAltitudeTypeChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].altitudeType = locationAltitudeType;
        }
    }

    onLocationGeoidSeparationChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].geoidSeparation = locationGeoidSeparation;
        }
    }

    onLocationAntennaHeightChanged: {
        if (!updating && knownDevices && lastUsedDeviceName > "") {
            knownDevices[lastUsedDeviceName].antennaHeight = locationAntennaHeight;
        }
    }

    //--------------------------------------------------------------------------

    function read() {
        console.log("Reading app settings");

        // Accessibility

        boldText = settings.boolValue(kKeyAccessibilityBoldText, false);
        plainBackgrounds = settings.boolValue(kKeyAccessibilityPlainBackgrounds, true);

        // Text

        fontFamily = settings.value(kKeyFontFamily, defaultFontFamily);
        textScaleFactor = settings.value(kKeyTextScaleFactor, 1);

        // Storage

        mapLibraryPaths = settings.value(kKeyMapLibraryPaths, kDefaultMapLibraryPath);

        // Spatial reference

        wkid = settings.numberValue(kKeyWkid, defaultWkid);

        // Location

        showActivationModeSettings = settings.boolValue(kKeyShowActivationModeSettings, false);

        discoverBluetooth = settings.boolValue(kKeyLocationDiscoverBluetooth, true);
        discoverBluetoothLE = settings.boolValue(kKeyLocationDiscoverBluetoothLE, false);
        discoverSerialPort = settings.boolValue(kKeyLocationDiscoverSerialPort, false);

        try {
            knownDevices = JSON.parse(settings.value(kKeyLocationKnownDevices, "{}"));
        } catch (e) {
            console.log("Error while parsing settings file.", e);
        }

        var internalFound = false;
        for (var deviceName in knownDevices) {
            // add default internal position source if necessary
            if (deviceName === kInternalPositionSourceName) {
                internalFound = true;
            }

            // clean up device settings if necessary (activationMode was previously connectionMode)
            if (!knownDevices[deviceName].activationMode && knownDevices[deviceName].activationMode !== 0) {
                knownDevices[deviceName].activationMode = kActivationModeAlways;
                delete knownDevices[deviceName].connectionMode;
            }
        }

        if (!internalFound) {
            createInternalSettings();
        } else {
            // update the label of the internal position source provider in case the system
            // language has changed since last using Survey123
            var receiverSettings = knownDevices[kInternalPositionSourceName];
            if (receiverSettings && receiverSettings["label"] !== internalPositionSourceName) {
                receiverSettings["label"] = internalPositionSourceName;
            }

            // must be set after creating the default internal source since this triggers
            // setting the current parameters from last used receiver
            lastUsedDeviceName = settings.value(kKeyLocationLastUsedDevice, "")
        }

        log();
    }

    //--------------------------------------------------------------------------

    function write() {
        console.log("Writing app settings");

        // Accessibility

        settings.setValue(kKeyAccessibilityBoldText, boldText, false);
        settings.setValue(kKeyAccessibilityPlainBackgrounds, plainBackgrounds, true);

        // Text

        settings.setValue(kKeyFontFamily, fontFamily, defaultFontFamily);
        settings.setValue(kKeyTextScaleFactor, textScaleFactor, 1);

        // Storage

        settings.setValue(kKeyMapLibraryPaths, mapLibraryPaths, kDefaultMapLibraryPath);

        // Spatial reference

        settings.setValue(kKeyWkid, wkid, defaultWkid);

        // Location

        settings.setValue(kKeyShowActivationModeSettings, showActivationModeSettings, false);

        settings.setValue(kKeyLocationDiscoverBluetooth, discoverBluetooth, true);
        settings.setValue(kKeyLocationDiscoverBluetoothLE, discoverBluetoothLE, false);
        settings.setValue(kKeyLocationDiscoverSerialPort, discoverSerialPort, false);

        settings.setValue(kKeyLocationLastUsedDevice, lastUsedDeviceName, "");
        settings.setValue(kKeyLocationKnownDevices, JSON.stringify(knownDevices), ({}));

        log();
    }

    //--------------------------------------------------------------------------

    function log() {
        console.log("App settings -");

        // Accessibility

        console.log("* boldText:", boldText);
        console.log("* plainBackgrounds:", plainBackgrounds);

        // Text

        console.log("* fontFamily:", fontFamily);
        console.log("* textScaleFactor:", textScaleFactor);

        // Storage

        console.log("* mapLibraryPaths:", mapLibraryPaths);

        // Spatial reference

        console.log("* wkid:", wkid);

        // Location

        console.log("* showActivationModeSettings", showActivationModeSettings);

        console.log("* discoverBluetooth:", discoverBluetooth);
        console.log("* discoverBluetoothLE:", discoverBluetoothLE);
        console.log("* discoverSerialPort:", discoverSerialPort);

        console.log("* lastUsedDeviceName:", lastUsedDeviceName);

        console.log("* locationAlertsVisual:", locationAlertsVisual);
        console.log("* locationAlertsSpeech:", locationAlertsSpeech);
        console.log("* locationAlertsVibrate:", locationAlertsVibrate);

        console.log("* locationMaximumDataAge:", locationMaximumDataAge);
        console.log("* locationMaximumPositionAge:", locationMaximumPositionAge);
        console.log("* locationSensorActivationMode:", locationSensorActivationMode);
        console.log("* locationSensorConnectionType:", locationSensorConnectionType);
        console.log("* locationAltitudeType:", locationAltitudeType);

        console.log("* locationGeoidSeparation:", locationGeoidSeparation);
        console.log("* locationAntennaHeight:", locationAntennaHeight);

        console.log("* knownDevices:", JSON.stringify(knownDevices));
    }

    //--------------------------------------------------------------------------
    // Location sensor receiver specific settings

    function getReceiverSettings(receiverName, defaultValue) {
        return knownDevices && receiverName > "" ? knownDevices[receiverName] : defaultValue;
    }

    function createDefaultSettingsObject(connectionType) {
        return {
            "locationAlertsVisual": connectionType === kConnectionTypeInternal ? false : true,
            "locationAlertsSpeech": connectionType === kConnectionTypeInternal ? false : true,
            "locationAlertsVibrate": connectionType === kConnectionTypeInternal ? false : true,
            "locationMaximumDataAge": 5000,
            "locationMaximumPositionAge": 5000,
            "connectionType": connectionType,
            "activationMode": kActivationModeAlways,
            "altitudeType": kAltitudeTypeMSL,
            "geoidSeparation": Number.NaN,
            "antennaHeight": Number.NaN
        }
    }

    function createInternalSettings() {
        if (knownDevices) {
            // use the fixed internal provider name as the identifier
            var name = kInternalPositionSourceName;

            if (!knownDevices[name]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeInternal);

                // use the localised internal provider name as the label
                receiverSettings["label"] = internalPositionSourceName;

                knownDevices[name] = receiverSettings;
                receiverListUpdated();
            }

            lastUsedDeviceName = name;

            return name;
        }

        return "";
    }

    function createExternalReceiverSettings(deviceName, device) {
        if (knownDevices && device && deviceName > "") {
            if (!knownDevices[deviceName]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeExternal);
                receiverSettings["receiver"] = device;
                receiverSettings["label"] = deviceName;

                knownDevices[deviceName] = receiverSettings;
                receiverListUpdated();
            }

            lastUsedDeviceName = deviceName;

            return deviceName;
        }

        return "";
    }

    function createNetworkSettings(hostname, port) {
        if (hostname > "" && port > "" && knownDevices) {
            var networkAddress = hostname + ":" + port;

            if (!knownDevices[networkAddress]) {
                var receiverSettings = createDefaultSettingsObject(kConnectionTypeNetwork);
                receiverSettings["hostname"] = hostname;
                receiverSettings["port"] = port;
                receiverSettings["label"] = networkAddress;

                knownDevices[networkAddress] = receiverSettings;
                receiverListUpdated();
            }

            lastUsedDeviceName = networkAddress;

            return networkAddress;
        }

        return "";
    }

    function deleteKnownDevice(deviceName) {
        try {
            delete knownDevices[deviceName];
            receiverListUpdated();
        }
        catch(e){
            console.log(e);
        }
    }

    //--------------------------------------------------------------------------
}
