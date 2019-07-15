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
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.3
import QtQml.Models 2.3

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Devices 1.0
import ArcGIS.AppFramework.Positioning 1.0

import "../XForms/GNSS"
import "../Controls"

SettingsLocationSensorTab {
    id: devicePage

    title: qsTr("Devices")
    icon: "images/satellite.png"

    // -------------------------------------------------------------------------

    property color unselectedColor: app.textColor
    property color selectedColor: app.titleBarBackgroundColor
    property color selectedBackgroundColor: "#FAFAFA"

    // Internal properties -----------------------------------------------------

    readonly property PositioningSourcesController controller: app.positionSourceManager.controller
    readonly property DeviceDiscoveryAgent discoveryAgent: controller.discoveryAgent
    readonly property PositionSource positionSource: controller.positionSource
    readonly property Device currentDevice: controller.currentDevice

    readonly property bool isConnecting: controller.isConnecting
    readonly property bool isConnected: controller.isConnected

    readonly property alias hostname: hostnameTextField.text
    readonly property alias port: portTextField.text

    readonly property bool bluetoothOnly: Qt.platform.os === "ios" || Qt.platform.os === "android"

    readonly property bool showInternal: appSettings.locationSensorConnectionType === appSettings.kConnectionTypeInternal
    readonly property bool showNetwork: appSettings.locationSensorConnectionType === appSettings.kConnectionTypeNetwork
    readonly property bool showDevices: appSettings.locationSensorConnectionType === appSettings.kConnectionTypeExternal

    readonly property string kDeviceTypeInternal: "Internal"
    readonly property string kDeviceTypeNetwork: "Network"
    readonly property string kDeviceTypeBluetooth: "Bluetooth"
    readonly property string kDeviceTypeBluetoothLE: "BluetoothLE"
    readonly property string kDeviceTypeSerialPort: "SerialPort"
    readonly property string kDeviceTypeUnknown: "Unknown"

    property bool initialized
    property bool updating

    // -------------------------------------------------------------------------

    Component.onCompleted: {
        controller.onSettingsPage = true;

        // add previously stored services to lists
        initializeCachedReceiversListModels(appSettings.knownDevices);

        // omit previously stored device from discovered devices list
        discoveryAgent.deviceFilter = function(device) {
            for (var i=0; i<cachedReceiversListModel.count; i++) {
                var cachedReceiver = cachedReceiversListModel.get(i);
                if (device && cachedReceiver && device.name === cachedReceiver.name) {
                    return false;
                }
            }
            return discoveryAgent.filter(device);
        }

        // start device discovery if necessary
        if (!isConnecting && !isConnected && showDevices && (discoveryAgent.running || !discoveryAgent.devices || discoveryAgent.devices.count == 0)) {
            discoverySwitch.checked = true;
            if (currentDevice) {
                controller.deviceSelected(currentDevice);
            }
        } else {
            discoverySwitch.checked = false;
        }

        initialized = true;
    }

    Component.onDestruction: {
        controller.onSettingsPage = false;

        // reset standard filter
        discoveryAgent.deviceFilter = function(device) { return discoveryAgent.filter(device); }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: appSettings

        onReceiverListUpdated: {
            initializeCachedReceiversListModels(appSettings.knownDevices);
        }
    }

    // -------------------------------------------------------------------------

    Connections {
        target: positionSource

        onSourceErrorChanged: {
            if (positionSource.sourceError !== PositionSource.NoError) {
                connectionErrorDialog.showError(app.positionSourceManager.errorString);
            }
        }
    }

    // -------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        // -------------------------------------------------------------------------

        GroupColumnLayout {
            Layout.fillWidth: true

            title: qsTr("Location receiver")

            AppRadioButton {
                Layout.fillWidth: true

                text: qsTr("System location service")
                checked: showInternal

                onCheckedChanged: {
                    if (initialized && !updating) {
                        if (checked) {
                            controller.disconnect();
                            appSettings.locationSensorConnectionType = controller.eConnectionType.internal;
                            appSettings.createInternalSettings();
                            discoverySwitch.checked = false;
                        }
                    }
                }
            }

            AppRadioButton {
                Layout.fillWidth: true

                text: qsTr("External GNSS receiver")
                checked: showDevices

                onCheckedChanged: {
                    if (initialized && !updating) {
                        if (checked) {
                            controller.disconnect();
                            appSettings.locationSensorConnectionType = controller.eConnectionType.external;
                            if (currentDevice) {
                                appSettings.createExternalReceiverSettings(currentDevice.name, currentDevice.toJson());
                                controller.deviceSelected(currentDevice)
                            } else {
                                discoverySwitch.checked = discoveryAgent.devices.count == 0;
                            }
                        }
                    }
                }
            }

            AppRadioButton {
                Layout.fillWidth: true

                text: qsTr("Network connection")
                checked: showNetwork

                onCheckedChanged: {
                    if (initialized && !updating) {
                        if (checked) {
                            controller.disconnect();
                            appSettings.locationSensorConnectionType = controller.eConnectionType.network;
                            discoverySwitch.checked = false;
                        }
                    }
                }
            }
        }

        // -------------------------------------------------------------------------

        GroupColumnLayout {
            Layout.fillWidth: true

            title: qsTr("Connection parameters")
            visible: showNetwork

            GridLayout {
                Layout.fillWidth: true

                columns: 3
                rows: 2

                // -------------------------------------------------------------------------

                AppText {
                    Layout.row: 0
                    Layout.column: 0

                    text: qsTr("Hostname")
                }

                AppTextField {
                    id: hostnameTextField

                    Layout.row: 0
                    Layout.column: 1
                    Layout.fillWidth: true

                    text: appSettings.hostname
                    placeholderText: qsTr("Hostname")
                }

                AppText {
                    Layout.row: 1
                    Layout.column: 0

                    text: qsTr("Port")
                }

                AppTextField {
                    id: portTextField

                    Layout.row: 1
                    Layout.column: 1
                    Layout.fillWidth: true

                    text: appSettings.port
                    placeholderText: qsTr("Port")
                }

                AppButton {
                    enabled: showNetwork && hostname > "" && port > 0

                    Layout.row: 1
                    Layout.column: 2

                    text: qsTr("Connect")

                    onClicked: {
                        appSettings.createNetworkSettings(hostname, port);
                        controller.networkHostSelected(hostname, port);
                    }
                }
            }
        }

        // -------------------------------------------------------------------------

        GroupColumnLayout {
            id: devicesGroup

            Layout.fillWidth: true
            Layout.fillHeight: true

            title: qsTr("External receivers")
            visible: showDevices

            layout.height: devicesGroup.height - layout.anchors.margins * 2 - layout.parent.anchors.margins
            implicitHeight: 0

            AppBusyIndicator {
                parent: devicesGroup

                anchors {
                    right: parent.right
                    rightMargin: 10 * AppFramework.displayScaleFactor
                    top: parent.top
                    topMargin: 10 * AppFramework.displayScaleFactor
                }

                implicitSize: 8

                running: discoveryAgent.running
            }

            Flow {
                Layout.fillWidth: true

                AppSwitch {
                    id: discoverySwitch

                    property bool updating

                    enabled: bluetoothCheckBox.checked || bluetoothLECheckBox.checked || usbCheckBox.checked

                    text: qsTr("Discover")

                    onCheckedChanged: {
                        if (initialized && !updating) {
                            if (checked) {
                                if (!discoveryAgent.running) {
                                    discoveryAgent.start();
                                }
                            } else {
                                controller.preventReconnect = true;
                                discoveryAgent.stop();
                                controller.preventReconnect = false;
                            }
                        }
                    }

                    Connections {
                        target: discoveryAgent

                        onRunningChanged: {
                            discoverySwitch.updating = true;
                            discoverySwitch.checked = discoveryAgent.running;
                            discoverySwitch.updating = false;
                        }
                    }
                }

                AppCheckBox {
                    id: bluetoothCheckBox

                    enabled: !discoverySwitch.checked
                    visible: true

                    text: qsTr("Bluetooth")

                    checked: appSettings.discoverBluetooth ? true : false
                    onCheckedChanged: {
                        if (initialized) {
                            appSettings.discoverBluetooth = checked ? true : false
                        }
                    }
                }

                AppCheckBox {
                    id: bluetoothLECheckBox

                    enabled: !discoverySwitch.checked
                    visible: true

                    text: qsTr("BluetoothLE")

                    checked: appSettings.discoverBluetoothLE ? true : false
                    onCheckedChanged: {
                        if (initialized) {
                            appSettings.discoverBluetoothLE = checked ? true : false
                        }
                    }
                }

                AppCheckBox {
                    id: usbCheckBox

                    enabled: !discoverySwitch.checked
                    visible: !bluetoothOnly

                    text: qsTr("USB/COM")

                    checked: appSettings.discoverSerialPort ? true : false
                    onCheckedChanged: {
                        if (initialized) {
                            appSettings.discoverSerialPort = checked ? true : false
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true

                height: 2 * AppFramework.displayScaleFactor
                color: "#20000000"
            }

            ListView {
                id: devicesListView

                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true
                spacing: 5 * AppFramework.displayScaleFactor

                model: discoveryAgent.devices
                delegate: deviceDelegate
            }
        }

        // -------------------------------------------------------------------------

        GroupColumnLayout {
            id: cachedReceiversGroup

            Layout.fillWidth: true
            Layout.fillHeight: true

            title: qsTr("Previously connected receivers")
            visible: cachedReceiversListModel.count > 0

            layout.height: cachedReceiversGroup.height - layout.anchors.margins * 2 - layout.parent.anchors.margins
            implicitHeight: 0

            Rectangle {
                Layout.fillWidth: true

                height: 2 * AppFramework.displayScaleFactor
                color: "#20000000"
            }

            ListView {
                id: cachedReceiversListView

                Layout.fillWidth: true
                Layout.fillHeight: true

                clip: true
                spacing: 5 * AppFramework.displayScaleFactor

                model: cachedReceiversDelegateModel
            }
        }

        // -------------------------------------------------------------------------

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !showDevices && !cachedReceiversGroup.visible
        }
    }

    // -------------------------------------------------------------------------

    DelegateModel {
        id: cachedReceiversDelegateModel

        model: cachedReceiversListModel
        delegate: cachedReceiverDelegate

        items.includeByDefault: false

        groups: VisualDataGroup {
            id: unsortedItems
            name: "unsorted"

            includeByDefault: true
            onChanged: cachedReceiversDelegateModel.sort()
        }

        function sort() {
            while (unsortedItems.count > 0) {
                var item = unsortedItems.get(0);
                var index = insertPosition(item);

                item.groups = "items";
                items.move(item.itemsIndex, index);
            }
        }

        function insertPosition(item) {
            var lower = 0;
            var upper = items.count;
            while (lower < upper) {
                var middle = Math.floor(lower + (upper - lower) / 2);
                var result = lessThan(item.model, items.get(middle).model);
                if (result) {
                    upper = middle;
                } else {
                    lower = middle + 1;
                }
            }
            return lower;
        }

        function lessThan(left, right) {
            switch (left.deviceType) {
            case kDeviceTypeInternal:
                return true;
            case kDeviceTypeBluetooth:
                if (right.deviceType === kDeviceTypeInternal) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetooth) {
                    return left.name.localeCompare(right.name) < 0 ? true : false;
                }
                return true;
            case kDeviceTypeBluetoothLE:
                if (right.deviceType === kDeviceTypeInternal) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetooth) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetoothLE) {
                    return left.name.localeCompare(right.name) < 0 ? true : false;
                }
                return true;
            case kDeviceTypeSerialPort:
                if (right.deviceType === kDeviceTypeInternal) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetooth) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetoothLE) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeSerialPort) {
                    return left.name.localeCompare(right.name) < 0 ? true : false;
                }
                return true;
            case kDeviceTypeNetwork:
                if (right.deviceType === kDeviceTypeInternal) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetooth) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeBluetoothLE) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeSerialPort) {
                    return false;
                }
                if (right.deviceType === kDeviceTypeNetwork) {
                    return left.name.localeCompare(right.name) < 0 ? true : false;
                }
                return true;
            default:
                if (right.deviceType === kDeviceTypeUnknown) {
                    return left.name.localeCompare(right.name) < 0 ? true : false;
                }
                return false;
            }
        }
    }

    // -------------------------------------------------------------------------

    ListModel {
        id: cachedReceiversListModel
    }

    // -------------------------------------------------------------------------

    Component {
        id: deviceDelegate

        Rectangle {
            id: delegateRect

            property bool isSelected: currentDevice && (currentDevice.name === name)

            height: deviceLayout.height
            width: devicesListView.width
            radius: 4 * AppFramework.displayScaleFactor

            color: isSelected ? selectedBackgroundColor : "transparent"
            opacity: parent.enabled ? 1.0 : 0.7

            ColumnLayout {
                id: deviceLayout

                width: parent.width
                spacing: 2 * AppFramework.displayScaleFactor

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10 * AppFramework.displayScaleFactor

                    StyledImage {
                        width: 25 * AppFramework.displayScaleFactor
                        height: width

                        Layout.preferredWidth: width
                        Layout.preferredHeight: height
                        Layout.alignment: Qt.AlignLeft

                        source: "./images/deviceType-%1.png".arg(deviceType)
                        color: delegateRect.isSelected && (isConnecting || isConnected) ? selectedColor : unselectedColor
                    }

                    AppText {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: name
                        color: delegateRect.isSelected && (isConnecting || isConnected) ? selectedColor : unselectedColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        verticalAlignment: Text.AlignVCenter

                        font {
                            pointSize: 14
                            bold: delegateRect.isSelected
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true

                    height: 1 * AppFramework.displayScaleFactor
                    color: "#20000000"
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    if (!isConnecting && !isConnected || currentDevice && currentDevice.name !== name) {
                        var device = discoveryAgent.devices.get(index);
                        appSettings.createExternalReceiverSettings(name, device.toJson());
                        controller.deviceSelected(device);
                    } else {
                        controller.deviceDeselected();
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    Component {
        id: cachedReceiverDelegate

        Rectangle {
            id: cachedReceiverRect

            property bool isInternal: deviceType === kDeviceTypeInternal
            property bool isNetwork: deviceType === kDeviceTypeNetwork
            property bool isDevice: !isInternal && !isNetwork

            property bool isSelected: isDevice && controller.useExternalGPS ? currentDevice && (currentDevice.name === name) :
                                                 isNetwork && controller.useTCPConnection ? name === hostname + ":" + port :
                                                             isInternal && controller.useInternalGPS

            height: cachedReceiverLayout.height
            width: cachedReceiversListView.width
            radius: 4 * AppFramework.displayScaleFactor

            color: isSelected ? selectedBackgroundColor : "transparent"
            opacity: parent.enabled ? 1.0 : 0.7

            ColumnLayout {
                id: cachedReceiverLayout

                width: parent.width
                spacing: 2 * AppFramework.displayScaleFactor

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10 * AppFramework.displayScaleFactor

                    StyledImage {
                        width: 25 * AppFramework.displayScaleFactor
                        height: width

                        Layout.preferredWidth: width
                        Layout.preferredHeight: height
                        Layout.alignment: Qt.AlignLeft

                        source: cachedReceiverRect.isDevice ? "./images/deviceType-%1.png".arg(deviceType) : ""
                        color: cachedReceiverRect.isSelected && (isConnecting || isConnected) ? selectedColor : unselectedColor
                    }

                    AppText {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: name
                        color: cachedReceiverRect.isSelected && (isConnecting || isConnected) ? selectedColor : unselectedColor
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                        verticalAlignment: Text.AlignVCenter

                        font {
                            pointSize: 14
                            bold: cachedReceiverRect.isSelected
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true

                    height: 1 * AppFramework.displayScaleFactor
                    color: "#20000000"
                }
            }

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    updating = true;

                    if (cachedReceiverRect.isDevice) {
                        if (!isConnecting && !isConnected || !controller.useExternalGPS || currentDevice && currentDevice.name !== name) {
                            var device = appSettings.knownDevices[name].receiver
                            appSettings.createExternalReceiverSettings(name, device);
                            controller.deviceSelected(Device.fromJson(JSON.stringify(device)));
                        } else {
                            controller.deviceDeselected();
                        }
                    } else if (cachedReceiverRect.isNetwork) {
                        if (!isConnecting && !isConnected || !controller.useTCPConnection || hostname > "" && port > "" && hostname + ":" + port !== name) {
                            var address = name.split(":");
                            appSettings.createNetworkSettings(address[0], address[1]);
                            controller.networkHostSelected(address[0], address[1]);
                        } else {
                            controller.deviceDeselected();
                        }
                    } else if (cachedReceiverRect.isInternal) {
                        controller.deviceDeselected();
                        appSettings.createInternalSettings();
                    } else {
                        controller.deviceDeselected();
                    }

                    updating = false;
                }
            }
        }
    }

    // -------------------------------------------------------------------------

    AppBusyIndicator {
        id: connectingIndicator

        height: 40 * AppFramework.displayScaleFactor
        width: height
        anchors.centerIn: parent

        running: isConnecting
        visible: running
    }

    // -------------------------------------------------------------------------

    function initializeCachedReceiversListModels(devicesList) {
        cachedReceiversListModel.clear();

        for (var deviceName in devicesList) {
            if (deviceName > "") {
                var receiverSettings = devicesList[deviceName];
                if (receiverSettings.receiver) {
                    cachedReceiversListModel.append({name: deviceName, deviceType: receiverSettings.receiver.deviceType});
                } else if (receiverSettings.hostname > "" && receiverSettings.port) {
                    cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeNetwork});
                } else {
                    cachedReceiversListModel.append({name: deviceName, deviceType: kDeviceTypeInternal});
                }
            }
        }
    }

    // -------------------------------------------------------------------------
}
