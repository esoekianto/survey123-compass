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
    id: control

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property bool initialized: false
    property var appearance: formElement ? formElement["@appearance"] : null
    property var constraint
    property var calculatedValue

    property var dateTimeValue: null
    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property date currentDate: new Date(dateTimeValue)
    readonly property date calculatedDate: XFormJS.clearSeconds(XFormJS.toDate(calculatedValue))
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && (!initialized || +calculatedDate !== +currentDate)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property var locale: xform.locale

    property bool debug: false

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    spacing: 5 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        constraint = formData.createConstraint(this, bindElement);
    }

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
            //console.log("onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    onLocaleChanged: {
        setControlText();
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform
        onCurrentActiveControlChanged: {
            if (currentActiveControl === null) {
                return;
            }

            if (currentActiveControl !== control) {
                closeControls();
            }
        }
    }

    function closeControls(){
        if (timePicker.visible) {
           timePicker.visible = false;
        }
        if (calendar.visible) {
           dateField.focus = false;
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        Layout.fillWidth: true

        layoutDirection: xform.languageDirection

        XFormDateField {
            id: dateField

            Layout.fillWidth: true

            readOnly: true
            text: ""
            placeholderText: qsTr("Date")
            actionEnabled: true
            actionIfReadOnly: true
            actionImage: calendar.visible ? "images/arrow-up.png" : "images/arrow-down.png"
            actionVisible: !control.readOnly
            altTextColor: changeReason === 3
            horizontalAlignment: layoutDirection == Qt.RightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

            onAction: {
                if (calendar.visible) {
                    calendar.forceActiveFocus();
                }
                else {
                    dateField.forceActiveFocus();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && dateTimeValue && !control.readOnly) {
                    formData.setValue(bindElement, dateTimeValue.valueOf());
                    changeReason = 1;
                    setControlText();
                }
                xform.controlFocusChanged(control, activeFocus, bindElement);
            }

            MouseArea {
                anchors.fill: parent
                enabled: calendar.visible
                onClicked: {
                    calendar.forceActiveFocus();
                }
            }
        }

        XFormDateField {
            id: timeField

            Layout.preferredWidth: parent.width / 3

            readOnly: true
            text: ""
            placeholderText: qsTr("Time")
            actionEnabled: true
            actionIfReadOnly: true
            actionImage: timePicker.visible ? "images/arrow-up.png" : "images/arrow-down.png"
            actionVisible: !control.readOnly
            altTextColor: changeReason === 3
            horizontalAlignment: layoutDirection == Qt.RightToLeft ? TextInput.AlignRight : TextInput.AlignLeft

            onActiveFocusChanged: {
                if (!activeFocus && dateTimeValue) {
                    formData.setValue(bindElement, dateTimeValue.valueOf());
                    changeReason = 1;
                    setControlText();
                }

                xform.controlFocusChanged(control, activeFocus, bindElement);
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!readOnly){
                        xform.controlFocusChanged(control, true, bindElement);
                        timePicker.visible = !timePicker.visible;
                    }
                    if (dateField.activeFocus) {
                        dateField.focus = false;
                    }
                }
            }
        }

        Loader {
            Layout.preferredWidth: timeField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth

            visible: !readOnly && dateTimeValue != null

            sourceComponent: XFormImageButton {
                source: "images/clear.png"
                color: "transparent"

                onClicked: {
                    forceActiveFocus();
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

    XFormCalendar {
        id: calendar

        Layout.fillWidth: true

        visible: dateField.activeFocus && !readOnly
        weekNumbersVisible: false
        enabled: !readOnly

        onClicked: {
            forceActiveFocus();
        }

        onVisibleChanged: {

            if (visible) {
                xform.ensureItemVisible(this);

                if (timePicker.visible) {
                    timePicker.visible = false
                }

                if (!dateTimeValue) {
                    initialized = true;
                    dateTimeValue = new Date();
                }
                else {
                    selectedDate = dateTimeValue;
                }
            }
        }

        onSelectedDateChanged: {
            if (!dateTimeValue || (dateTimeValue && selectedDate.valueOf() !== dateTimeValue.valueOf())) {
                var date = dateTimeValue ? new Date(dateTimeValue.valueOf()) : new Date();

                date.setFullYear(selectedDate.getFullYear());
                date.setMonth(selectedDate.getMonth());
                date.setDate(selectedDate.getDate());
                XFormJS.clearSeconds(date);

                dateTimeValue = date;
                formData.setValue(bindElement, date.valueOf());
                xform.controlFocusChanged(control, activeFocus, bindElement);
            }
        }
    }

    XFormTimePicker {
        id: timePicker

        Layout.fillWidth: true
        Layout.minimumHeight: (120 * AppFramework.displayScaleFactor) * app.textScaleFactor
        visible: false
        enabled: !readOnly
        appearance: control.appearance
        style: xform.style
        useArrow: true
        leftRightInset: xform.languageDirection === Qt.LeftToRight ? control.width - (timeField.x + timeField.width) : timeField.x

        onVisibleChanged: {
            if (visible) {
                xform.ensureItemVisible(this);

                if (!dateTimeValue) {
                    initialized = true;
                    dateTimeValue = new Date();
                }
                else {
                    selectedDate = dateTimeValue;
                }
            }
            if (!visible) {
                if (dateTimeValue) {
                    formData.setValue(bindElement, dateTimeValue.valueOf());
                    changeReason = 1;
                    setControlText();
                }

                xform.controlFocusChanged(control, activeFocus, bindElement);
            }
        }

        onSelectedDateChanged: {

            if (!dateTimeValue || (dateTimeValue && selectedDate.valueOf() !== dateTimeValue.valueOf())) {
                var date = dateTimeValue ? new Date(dateTimeValue.valueOf()) : new Date();

                date.setHours(selectedDate.getHours());
                date.setMinutes(selectedDate.getMinutes());
                XFormJS.clearSeconds(date);

                timeField.text = XFormJS.formatTime(date, appearance, locale);

                dateTimeValue = date;
                formData.setValue(bindElement, date.valueOf());
                xform.controlFocusChanged(control, activeFocus, bindElement);
            }
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var date = XFormJS.clearSeconds(XFormJS.toDate(value));

        if (debug) {
            console.log("dateTime setValue:", reason, value, date);
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && XFormJS.equalDates(date, dateTimeValue)) {
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
            resetControl();
            formData.setValue(bindElement, undefined);
        } else {
            initialized = true;
            dateTimeValue = date;
            setControlText();
            formData.setValue(bindElement, dateTimeValue.valueOf());
        }
    }

    //--------------------------------------------------------------------------

    function resetControl() {
        calendar.selectedDate = new Date();
        timePicker.selectedDate = new Date();
        dateTimeValue = null;
        initialized = false;
        setControlText();
    }

    //--------------------------------------------------------------------------

    function setControlText() {
        dateField.text = dateTimeValue ? XFormJS.formatDate(dateTimeValue, appearance, locale) : "";
        timeField.text = dateTimeValue ? XFormJS.formatTime(dateTimeValue, appearance, locale) : "";
    }

    //--------------------------------------------------------------------------
}
