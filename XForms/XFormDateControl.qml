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

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property alias currentDate: calendar.selectedDate
    readonly property date calculatedDate: XFormJS.clearTime(XFormJS.toDate(calculatedValue))
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && (!initialized || +calculatedDate !== +currentDate)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

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
            if (debug) {
                console.log("onCalculatedValueChanged:", calculatedValue, "changeBinding:", JSON.stringify(formData.changeBinding), "changeReason:", changeReason);
            }
            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    RowLayout {
        layoutDirection: xform.languageDirection

        XFormDateField {
            id: dateField

            Layout.fillWidth: true

            readOnly: true
            text: initialized ? XFormJS.formatDate(currentDate, appearance, xform.locale) : ""
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
                } else {
                    dateField.forceActiveFocus();
                }
            }

            onActiveFocusChanged: {
                if (!activeFocus && !control.readOnly) {
                    initialized = true;
                    formData.setValue(bindElement, XFormJS.clearTime(currentDate).valueOf());
                }

                xform.controlFocusChanged(control, activeFocus, bindElement);
            }

            MouseArea {
                anchors.fill: parent
                enabled: calendar.visible
                onClicked: calendar.forceActiveFocus();
            }
        }

        Loader {
            Layout.preferredWidth: dateField.height * 0.9
            Layout.preferredHeight: Layout.preferredWidth

            visible: !readOnly && dateField.length > 0

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

            Layout.preferredWidth: dateField.height * 0.9
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
        weekNumbersVisible: appearance === "week-number" //true
        enabled: !readOnly

        onVisibleChanged: {
            if (visible) {
                xform.ensureItemVisible(this);
            }
        }

        onClicked: {
            changeReason = 1;
            forceActiveFocus();
            //xform.nextControl(this, true);
        }

        onDoubleClicked: {
            forceActiveFocus();
            xform.nextControl(this, true);
        }
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var date = XFormJS.clearTime(XFormJS.toDate(value));

        if (debug) {
            console.log("date setValue:", reason, value, date);
        }

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

            formData.setValue(bindElement, undefined);

            // set calendar date to 'now' becuase there is no value
            // this will also reset the calendar in repeats.
            currentDate = new Date();
        } else {
            initialized = true;
            currentDate = date;
            formData.setValue(bindElement, currentDate.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
