/* Copyright 2015 Esri
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

import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0
import ArcGIS.AppFramework.Networking 1.0

import "../Controls"

//------------------------------------------------------------------------------

FocusScope {
    id: inputArea

    property alias username: usernameField.text
    property alias password: passwordField.text
    property bool hideCancel: false
    property string fontFamily

    property color signInButtonColor: "#0079c0" // "#e98d32"
    property color signInButtonBusyColor: "#84b9de"
    property color signInButtonHoverColor: "#015e95" // "#e36b00"

    property Settings settings: portal.settings

    signal rejected()

    property alias saveUserChecked: saveUserCheckBox.checked

    readonly property string kSettingSaveUsername: "saveUsername"
    readonly property string kSettingIdpUsername: "idpUsername"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        Networking.clearAccessCache();

        if (settings) {
            saveUserChecked = settings.boolValue(portal.settingName(kSettingSaveUsername), true);

            if (portal.networkAuthentication) {
                username = settings.value(portal.settingName(kSettingIdpUsername), username);
            }
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: portal

        onSignedInChanged: {
            if (portal.signedIn) {
                if (settings) {

                    if (saveUserChecked) {
                        portal.writeUserSettings();
                        settings.setValue(portal.settingName(kSettingIdpUsername), username);
                    } else {
                        portal.clearUserSettings();
                        settings.remove(portal.settingName(kSettingIdpUsername));
                    }

                    settings.setValue(portal.settingName(kSettingSaveUsername), saveUserChecked);
                }
            }
        }

        onError: {
            console.log("BuiltInSignInView.onError:", JSON.stringify(error, undefined, 2));
            portal.busy = false;

            switch (error.messageCode) {
            case messageCodePasswordExired:
                showResetPasswordPage();
                break;
            }
        }
    }

    //--------------------------------------------------------------------------

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20 * AppFramework.displayScaleFactor
        }
        
        spacing: 5 * AppFramework.displayScaleFactor

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        
        Text {
            id: usernameText
            
            Layout.fillWidth: true
            
            text: qsTr("Username")
            horizontalAlignment: Text.AlignLeft
            font {
                pointSize: 14
                bold: false
                family: fontFamily
            }
        }
        
        TextField {
            id: usernameField
            
            Layout.fillWidth: true
            
            placeholderText: portal.networkAuthentication ? "DOMAIN\\username" : usernameText.text
            font {
                pointSize: 18
                family: fontFamily
            }
            style: TextFieldStyle {
                renderType: Text.QtRendering
            }
            activeFocusOnTab: true
            focus: true
            inputMethodHints: Qt.ImhNoAutoUppercase + Qt.ImhNoPredictiveText + Qt.ImhSensitiveData
            textColor: "black"
            
            onAccepted: {
                acceptButton.tryClick();
            }
        }
        
        Text {
            id: passwordText
            
            Layout.fillWidth: true
            
            text: qsTr("Password")
            horizontalAlignment: Text.AlignLeft
            font: usernameText.font
        }
        
        TextField {
            id: passwordField
            
            Layout.fillWidth: true
            
            echoMode: TextInput.Password
            placeholderText: passwordText.text
            font: usernameField.font
            style: usernameField.style
            activeFocusOnTab: true
            textColor: "black"
            
            onAccepted: {
                acceptButton.tryClick();
            }
        }
        
        Item {
            Layout.preferredHeight: 10 * AppFramework.displayScaleFactor
            Layout.fillWidth: true
        }

        StyledSwitchBox {
            id: saveUserCheckBox

            Layout.fillWidth: true

            text: qsTr("Remember me")
            visible: settings !== null
            fontFamily: inputArea.fontFamily
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
        
        RowLayout {
            Layout.fillWidth: true
            
            Button {
                id: acceptButton
                
                text: busy ? qsTr("Signing In") : qsTr("Sign In")
                isDefault: true
                enabled: !busy && usernameField.text.trim().length > 0 && passwordField.text.trim().length > 0
                onClicked: {
                    tryClick();
                }
                
                function tryClick() {
                    if (!enabled) {
                        return;
                    }
                    
                    portal.setCredentials(usernameField.text.trim(), passwordField.text.trim());
                }
                
                style: ButtonStyle {
                    padding {
                        left: 10 * AppFramework.displayScaleFactor
                        right: 10 * AppFramework.displayScaleFactor
                    }
                    
                    label: Text {
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: control.enabled ? (control.isDefault ? "white" : "dimgray") : "lightgray"
                        text: control.text
                        font {
                            pointSize: 16
                            capitalization: Font.AllUppercase
                        }
                    }
                    
                    background: Rectangle {
                        color: busy
                               ? signInButtonBusyColor
                               : (control.hovered | control.pressed)
                                 ? (control.isDefault ? signInButtonHoverColor : "darkgray")
                                 : (control.isDefault ? signInButtonColor : "lightgray")
                        border {
                            color: control.activeFocus ? (control.isDefault ? signInButtonHoverColor : "darkgray") : "transparent"
                            width: control.activeFocus ? 2 : 1
                        }
                        radius: 4
                        implicitWidth: 120 * AppFramework.displayScaleFactor
                    }
                }
            }
            
            Item {
                Layout.fillWidth: true

                height: 1
                visible: !hideCancel
            }
            
            Button {
                id: rejectButton
                
                text: qsTr("Cancel")
                enabled: !busy
                visible: !hideCancel
                style: acceptButton.style

                onClicked: {
                    inputArea.rejected();
                }
            }
        }
        
        //                        Text {
        //                            Layout.fillWidth: true
        //
        //                            text: qsTr('<a href="%1">Forgot password?</a> <a href="%2">Forgot username?</a> <a href="reset">Change password?</a>').arg(forgotUrl("password")).arg(forgotUrl("username"))
        //                            textFormat: Text.RichText
        //                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        //                            color: "black"
        //                            font {
        //                                pointSize: 13
        //                            }
        //                            horizontalAlignment: Text.AlignHCenter
        //
        //                            onLinkActivated: {
        //                                if (link == "reset") {
        //                                    showResetPasswordPage();
        //                                } else {
        //                                    Qt.openUrlExternally(link);
        //                                }
        //                            }
        //                        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: resetPassword

        Rectangle {
            id: resetPasswordPage

            signal passwordChanged()
            signal passwordResetError(var error)

            color: "white"

            onPasswordChanged: {
                console.log("onPasswordChanged");

                password = newPasswordField.text;

                parent.pop();
            }

            onPasswordResetError: {
                resetError.text = error.message;
            }

            Rectangle {
                id: portalsBanner

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                height: portalsBannerRow.height + 20
                color: bannerColor

                RowLayout {
                    id: portalsBannerRow

                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }

                    ImageButton {
                        width: 20 * AppFramework.displayScaleFactor
                        height: width

                        source: "images/back.png"

                        onClicked: {
                            stackView.pop()
                        }
                    }

                    Text {
                        Layout.fillWidth: true

                        text: qsTr("Reset Password")
                        font {
                            pointSize: titleText.font.pointSize
                            bold: titleText.font.bold
                            family: fontFamily
                        }
                        color: bannerTextColor
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            ColumnLayout {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: portalsBanner.bottom
                    bottom: parent.bottom
                    margins: 10 * AppFramework.displayScaleFactor
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Text {
                    Layout.fillWidth: true

                    text: qsTr("It's time to change your password <b>%1</b>").arg(username)
                    textFormat: Text.RichText
                    color: "black"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                    font {
                        pointSize: 18
                        family: fontFamily
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Text {
                    id: oldPasswordLabel
                    Layout.fillWidth: true

                    text: qsTr("Old Password")
                    horizontalAlignment: Text.AlignLeft
                    font: usernameText.font
                }

                TextField {
                    id: oldPasswordField

                    Layout.fillWidth: true

                    echoMode: TextInput.Password
                    placeholderText: oldPasswordLabel.text
                    font: usernameField.font
                    style: usernameField.style
                    activeFocusOnTab: true
                    textColor: "black"

                    onAccepted: {
                        resetButton.tryClick();
                    }
                }

                Text {
                    id: newPasswordLabel

                    Layout.fillWidth: true

                    text: qsTr("New Password")
                    horizontalAlignment: Text.AlignLeft
                    font: usernameText.font
                }

                TextField {
                    id: newPasswordField

                    Layout.fillWidth: true

                    echoMode: TextInput.Password
                    placeholderText: newPasswordLabel.text
                    font: usernameField.font
                    style: usernameField.style
                    activeFocusOnTab: true
                    textColor: "black"

                    onAccepted: {
                        resetButton.tryClick();
                    }
                }

                Text {
                    id: confirmPasswordLabel

                    Layout.fillWidth: true

                    text: qsTr("Confirm Password")
                    horizontalAlignment: Text.AlignLeft
                    font: usernameText.font
                }

                TextField {
                    id: confirmPasswordField

                    Layout.fillWidth: true

                    echoMode: TextInput.Password
                    placeholderText: confirmPasswordLabel.text
                    font: usernameField.font
                    style: usernameField.style
                    activeFocusOnTab: true
                    textColor: (text === newPasswordField.text) ? "black" : "red"

                    onAccepted: {
                        resetButton.tryClick();
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                Text {
                    id: resetError

                    Layout.fillWidth: true

                    visible: text > ""
                    color: "red"
                    font {
                        pointSize: 14
                        family: fontFamily
                    }
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    id: resetButton

                    Layout.alignment: Qt.AlignCenter

                    text: resetRequest.isBusy ? qsTr("Changing Password") : qsTr("Change Password")
                    isDefault: true
                    enabled: !resetRequest.isBusy &&
                             oldPasswordField.text.trim().length > 0 &&
                             newPasswordField.text.trim().length > 0 &&
                             confirmPasswordField.text.trim().length > 0 &&
                             newPasswordField.text == confirmPasswordField.text

                    onClicked: {
                        tryClick();
                    }

                    function tryClick() {
                        if (!enabled) {
                            return;
                        }

                        resetRequest.sendRequest(username, oldPasswordField.text, newPasswordField.text);
                    }

                    style: ButtonStyle {
                        padding {
                            left: 10 * AppFramework.displayScaleFactor
                            right: 10 * AppFramework.displayScaleFactor
                        }

                        label: Text {
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: control.enabled ? (control.isDefault ? "white" : "dimgray") : "gray"
                            text: control.text
                            font {
                                pointSize: 14
                                capitalization: Font.AllUppercase
                            }
                        }

                        background: Rectangle {
                            color: (control.hovered | control.pressed) ? (control.isDefault ? signInButtonHoverColor : "darkgray") : (control.isDefault ? signInButtonColor : "lightgray")
                            border {
                                color: control.activeFocus ? (control.isDefault ? signInButtonHoverColor : "darkgray") : "transparent"
                                width: control.activeFocus ? 2 : 1
                            }
                            radius: 4
                            implicitWidth: 120 * AppFramework.displayScaleFactor
                        }
                    }
                }
            }

            ColorBusyIndicator {
                anchors.centerIn: parent

                backgroundColor: signInView.bannerColor
                running: resetRequest.isBusy
                visible: running
            }

            NetworkRequest {
                id: resetRequest

                property string text
                property bool isBusy: readyState == NetworkRequest.ReadyStateProcessing || readyState == NetworkRequest.ReadyStateSending

                method: "POST"
                responseType: "json"

                onReadyStateChanged: {
                    if (readyState === NetworkRequest.ReadyStateComplete)
                    {
                        if (status === 200) {
                            console.log("reset response:", JSON.stringify(response));

                            if (response.success) {
                                resetPasswordPage.passwordChanged();
                            } else if (response.error) {
                                resetPasswordPage.passwordResetError(response.error);
                            }
                        }
                    }
                }

                onErrorTextChanged: {
                    resetPasswordPage.passwordResetError({
                                                             message: errorText
                                                         });
                }

                function sendRequest(username, password, newPassword) {
                    var portalUrlInfo = AppFramework.urlInfo(portal.portalUrl);

                    portalUrlInfo.scheme = "https";

                    url = portalUrlInfo.url + "/sharing/rest/community/users/" + username + "/reset";

                    var formData = {
                        f: "pjson",
                        password: password,
                        newPassword: newPassword
                    };

                    send(formData);
                }
            }
        }
    }

    function showResetPasswordPage() {
        stackView.push({
                           item: resetPassword
                       });
    }

    //--------------------------------------------------------------------------
}
