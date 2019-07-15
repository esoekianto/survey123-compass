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

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

ColumnLayout {
    id: _control

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property var appearance: formElement ? formElement["@appearance"] : null;

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool initialized: false
    property var calculatedValue
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property alias currentDate: timePicker.selectedDate
    readonly property date calculatedDate: XFormJS.clearSeconds(XFormJS.toDate(calculatedValue))
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && (!initialized || +calculatedDate !== +currentDate)

    property bool debug: false

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
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

    Connections {
        target: xform
        onCurrentActiveControlChanged: {
            if (currentActiveControl !== null && currentActiveControl !== _control){
                timePicker.visible = false;
            }
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: xform.languageDirection

        XFormDateField {
            id: timeField

            Layout.fillWidth: true

            readOnly: true
            text: initialized ? XFormJS.formatTime(currentDate, appearance, xform.locale) : ""
            placeholderText: qsTr("Time")
            actionEnabled: true
            actionIfReadOnly: true
            actionImage: timePicker.visible ? "images/arrow-up.png" : "images/arrow-down.png"
            actionVisible: !_control.readOnly
            altTextColor: changeReason === 3
            horizontalAlignment: layoutDirection == Qt.RightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

            onAction: {
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!readOnly){
                        xform.controlFocusChanged(_control, true, bindElement);
                        timePicker.visible = !timePicker.visible;
                    }
                }
            }
        }

        Loader {
            Layout.preferredWidth: timeField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth
            visible: !readOnly && timeField.length > 0

            sourceComponent: XFormImageButton {
                source: "images/clear.png"
                color: "transparent"

                onClicked: {
                    setValue(undefined, 1);
                }
            }
        }

        Loader {
            id: calculateButtonLoader

            Layout.preferredWidth: timeField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth

            active: false
            visible: showCalculate && active

            sourceComponent: XFormImageButton {
                source: "images/refresh_update.png"
                color: "transparent"

                onClicked: {
                    changeReason = 0;
                    formData.triggerCalculate(bindElement);
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    XFormTimePicker {
        id: timePicker

        Layout.fillWidth: true
        Layout.minimumHeight: (120 * AppFramework.displayScaleFactor) * app.textScaleFactor
        visible: false
        enabled: !readOnly
        appearance: _control.appearance
        style: xform.style
        useArrow: true
        leftRightInset: xform.languageDirection === Qt.LeftToRight ? _control.width - timeField.width : timeField.x

        onSelectedDateChanged: {
            initialized = isValid;
            formData.setValue(bindElement, selectedDate.valueOf());
            xform.controlFocusChanged(_control, activeFocus, bindElement);
        }

        onEditingFinished: {
            changeReason = 1;
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var date = XFormJS.clearSeconds(XFormJS.toDate(value));

        if (reason) {
            if (reason === 1 && changeReason === 3 && XFormJS.equalDates(date, currentDate)) {
                if (debug) {
                    console.log("date setValue == calculated:", JSON.stringify(date));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        if (XFormJS.isEmpty(date)) {
            initialized = false;
            timePicker.clear();
            formData.setValue(bindElement, undefined);
        } else {
            initialized = true;
            currentDate = date;
            formData.setValue(bindElement, currentDate.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
