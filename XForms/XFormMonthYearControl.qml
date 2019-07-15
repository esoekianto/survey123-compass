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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Rectangle {
    id: control

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property var appearance: formElement ? formElement["@appearance"] : null;
    property bool monthYear: appearance !== "year"
    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    readonly property date todayDate: clearDate(new Date())
    readonly property date currentDate: clearDate(XFormJS.toDate(dateValue));
    readonly property date calculatedDate: clearDate(XFormJS.toDate(calculatedValue))
    readonly property bool showCalculate: !readOnly && changeReason === 1 && calculatedValue !== undefined && +calculatedDate !== +currentDate

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property date dateValue: new Date()
    property int dateMonth
    property int dateYear
    readonly property int monthRepeatInterval: 100
    readonly property int yearRepeatInterval: 50


    property int barTextSize: xform.style.implicitTextHeight
    property int barHeight: Math.round(barTextSize * 1.1) + padding * 2
    property var locale: xform.locale
    property int padding: 2 // * AppFramework.displayScaleFactor
    property color gridColor: "#ccc"

    property bool debug: false

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    border {
        color: xform.style.inputBorderColor
        width: 1
    }

    height: valueLayout.height + padding * 2
    radius: 4 * AppFramework.displayScaleFactor
    color: xform.style.inputBackgroundColor

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

    onDateValueChanged: {
        dateMonth = dateValue.getMonth();
        dateYear = dateValue.getFullYear();
        formData.setValue(bindElement, dateValue.valueOf());
    }

    //--------------------------------------------------------------------------

    RowLayout {
        id: valueLayout

        anchors {
            left: parent.left
            right: parent.right
            margins: padding
            verticalCenter: parent.verticalCenter
        }

        enabled: !readOnly
        spacing: padding * 3

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 0

            RowLayout {
                Layout.fillWidth: true

                visible: monthYear

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height * 1.5

                    source: "images/arrow-left.png"
                    repeatInterval: monthRepeatInterval

                    onClicked: updateMonth(-1)
                    onRepeat: updateMonth(-1)
                }

                Text {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    text: control.locale.standaloneMonthName(dateMonth)
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: changeReason === 3 ? xform.style.inputAltTextColor : xform.style.inputTextColor
                    font {
                        family: xform.style.inputFontFamily
                        pointSize: xform.style.inputPointSize
                    }
                }

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height * 1.5

                    source: "images/arrow-right.png"
                    repeatInterval: monthRepeatInterval

                    onClicked: updateMonth(1)
                    onRepeat: updateMonth(1)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1

                visible: monthYear
                color: gridColor
            }

            //--------------------------------------------------------------------------

            RowLayout {
                Layout.fillWidth: true

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height * 1.5

                    source: "images/arrow-left.png"
                    repeatInterval: yearRepeatInterval

                    onClicked: updateYear(-1)
                    onRepeat: updateYear(-1)
                }

                Text {
                    Layout.fillHeight: true
                    Layout.fillWidth: true

                    text: dateYear
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: changeReason === 3 ? xform.style.inputAltTextColor : xform.style.inputTextColor
                    font {
                        family: xform.style.inputFontFamily
                        pointSize: xform.style.inputPointSize
                    }
                }

                XFormHoverButton {
                    Layout.preferredHeight: parent.height
                    Layout.preferredWidth: parent.height * 1.5

                    source: "images/arrow-right.png"
                    repeatInterval: yearRepeatInterval

                    onClicked: updateYear(1)
                    onRepeat: updateYear(1)
                }
            }
        }

        Loader {
            Layout.preferredHeight: barHeight
            Layout.preferredWidth: Layout.preferredHeight

            visible: !readOnly && +currentDate !== +todayDate

            sourceComponent: XFormImageButton {
                source: "images/clear.png"
                color: "transparent"

                onClicked: {
                    forceActiveFocus();
                    setValue(new Date().valueOf(), 1);
                }
            }
        }

        Loader {
            id: calculateButtonLoader

            Layout.preferredHeight: barHeight
            Layout.preferredWidth: Layout.preferredHeight

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

    function updateMonth(offset) {
        var date = new Date(dateValue.valueOf());
        date.setMonth((date.getMonth() + offset) % 12);
        clearDate(date);
        dateValue = date;
        changeReason = 1;
    }

    //--------------------------------------------------------------------------

    function updateYear(offset) {
        var date = new Date(dateValue.valueOf());
        date.setFullYear(date.getFullYear() + offset);
        clearDate(date);
        dateValue = date;
        changeReason = 1;
    }

    //--------------------------------------------------------------------------

    function clearDate(date) {
        if (!XFormJS.isValidDate(date)) {
            return date;
        }

        if (!monthYear) {
            date.setMonth(0);
        }

        date.setDate(1);
        date.setHours(0);
        date.setMinutes(0);
        date.setSeconds(0);
        date.setMilliseconds(0);

        return date;
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        var date = clearDate(XFormJS.toDate(value));

        if (reason) {
            if (reason === 1 && changeReason === 3 && XFormJS.equalDates(date, dateValue)) {
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
            dateValue = clearDate(new Date());
            formData.setValue(bindElement, undefined);
        } else {
            dateValue = date;
            formData.setValue(bindElement, dateValue.valueOf());
        }
    }

    //--------------------------------------------------------------------------
}
