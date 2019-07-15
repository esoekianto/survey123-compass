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
import QtQuick.Controls 1.3

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

RowLayout {
    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var constraint
    property var calculatedValue

    property var appearance: (formElement ? formElement["@appearance"] : "") || ""

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property alias currentValue: textArea.text
    readonly property bool showCalculate: !binding.isReadOnly && changeReason === 1 && calculatedValue !== undefined && calculatedValue != currentValue

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool valid: true
    property string errorMessage
    property XFormControlGroup controlGroup: XFormJS.findParent(this, undefined, "XFormControlGroup")

    property bool debug: false

    property int buttonSize: 25 * AppFramework.displayScaleFactor * xform.style.textScaleFactor

    //--------------------------------------------------------------------------

    width: parent.width
    height: xform.style.multilineTextHeight

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        controlGroup.valid = Qt.binding(function () { return valid; });
        controlGroup.errorMessage = Qt.binding(function () { return errorMessage; });
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            valid = true;
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    onCurrentValueChanged: {
        valid = true;
    }

    //--------------------------------------------------------------------------

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true

        color: xform.style.inputBackgroundColor
        border {
            color: textArea.activeFocus
                   ? xform.style.inputActiveBorderColor
                   : xform.style.inputBorderColor
        }
        radius: 3 * AppFramework.displayScaleFactor

        TextArea {
            id: textArea

            property int maximumLength: 255
            property string previousText: text

            anchors {
                fill: parent
                margins: 2 * AppFramework.displayScaleFactor
            }

            readOnly: !editable || binding.isReadOnly
            wrapMode: TextEdit.WordWrap
            textColor: changeReason === 3
                   ? xform.style.inputAltTextColor
                   : xform.style.inputTextColor

            backgroundVisible: false
            frameVisible: false

            font {
                pointSize: xform.style.inputPointSize
                bold: xform.style.inputBold
                family: xform.style.inputFontFamily
            }

            Component.onCompleted: {
                constraint = formData.createConstraint(this, bindElement);

                var fieldLength = 255;
                var imh = Qt.ImhNone;

                if (Qt.platform.os === "android") {
                    imh |= Qt.ImhNoPredictiveText;
                }
                if (appearance.indexOf("nopredictivetext") >= 0) {
                    imh |= Qt.ImhNoPredictiveText;
                } else if (appearance.indexOf("predictivetext") >= 0) {
                    imh &= ~Qt.ImhNoPredictiveText;
                }

                inputMethodHints = imh;

                var esriProperty = bindElement["@esri:fieldLength"];
                if (esriProperty > "") {
                    var n = Number(esriProperty);
                    if (isFinite(n)) {
                        fieldLength = n;
                    }
                }

                if (fieldLength > 0) {
                    maximumLength = fieldLength;
                }
            }


            onActiveFocusChanged: {
                if (!activeFocus) {
                    var value;
                    var validate = false;

                    if (text > "") {
                        validate = true;
                        value = text;
                    }

                    formData.setValue(bindElement, value);

                    if (validate && constraint && relevant) {
                        var error = constraint.validate();
                        if (error) {
                            valid = false;
                            errorMessage = error.message;
                            if (!controlGroup.inlineErrorMessages) {
                                xform.validationError(error);
                            }
                        } else {
                            valid = true;
                            errorMessage = "";
                        }
                    }
                }

                xform.controlFocusChanged(this, activeFocus, bindElement);
            }

            onLengthChanged: {
                if (length === 0) {
                    formData.setValue(bindElement, undefined);
                }
            }

            onTextChanged: {
                if (text.length > maximumLength) {
                    var cursor = cursorPosition;
                    text = previousText;
                    if (cursor > text.length) {
                        cursorPosition = text.length;
                    } else {
                        cursorPosition = cursor - 1;
                    }
                }
                previousText = text
            }

            Keys.onPressed: {
                if (!readOnly) {
                    changeReason = 1;
                }
            }
        }

        XFormInputCharacterCount {
            anchors {
                top: parent.bottom
                right: parent.right
            }

            control: textArea
        }
    }

    //--------------------------------------------------------------------------

    Column {
        Layout.alignment: Qt.AlignTop

        spacing: 5 * AppFramework.displayScaleFactor

        Loader {
            width: buttonSize
            height: width

            visible: !textArea.readOnly && textArea.length > 0

            sourceComponent: XFormImageButton {
                source: "images/clear.png"
                color: "transparent"

                onClicked: {
                    valid = true;
                    setValue(undefined, 1);
                    textArea.forceActiveFocus();
                }

                onPressAndHold: {
                    valid = true;
                    setValue(binding.defaultValue);
                    textArea.forceActiveFocus();
                }
            }
        }

        Loader {
            id: calculateButtonLoader

            width: buttonSize
            height: width

            sourceComponent: XFormImageButton {
                source: "images/refresh_update.png"
                color: "transparent"

                onClicked: {
                    textArea.forceActiveFocus();
                    changeReason = 0;
                    formData.triggerCalculate(bindElement);
                }
            }

            active: false
            visible: showCalculate && active
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (reason) {
            if (reason === 1 && changeReason === 3 && value == currentValue) {
                if (debug) {
                    console.log("input setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        var isEmpty = XFormJS.isEmpty(value);
        currentValue = isEmpty ? "" : value.toString();
        formData.setValue(bindElement, XFormJS.toBindingType(value, bindElement));
    }

    //--------------------------------------------------------------------------
}
