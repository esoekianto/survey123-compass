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
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

RowLayout {
    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property bool readOnly: !editable || binding.isReadOnly
    property alias minimumValue: slider.from
    property alias maximumValue: slider.to
    property alias step: slider.stepSize
    property bool rightToLeft: xform.languageDirection === Qt.RightToLeft

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
        minimumValue = getAttributeValue(formElement, "start", 0);
        maximumValue = getAttributeValue(formElement, "end", 10);
        step = getAttributeValue(formElement, "step", 1);
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            setValue(undefined);
        }
    }

    //--------------------------------------------------------------------------

    onRightToLeftChanged: {
        slider.value = maximumValue - slider.value;
    }

    Slider {
        id: slider

        Layout.fillWidth: true

        property bool isEmpty: true
        property bool inSetValue: false

        value: rightToLeft ? maximumValue : minimumValue

        onValueChanged: {
            if (!inSetValue) {
                var _value = rightToLeft ? maximumValue - value : value;
                formData.setValue(bindElement, _value);
                isEmpty = false;
            }
        }

        onPressedChanged: {
            if (slider.isEmpty && pressed) {
                slider.valueChanged();
            }
        }

        function setValue(_value) {
            inSetValue = true;
            value = rightToLeft ? maximumValue - _value : _value;
            inSetValue = false;
        }

        background: Rectangle {
            implicitWidth: 200 * AppFramework.displayScaleFactor
            implicitHeight: 4 * AppFramework.displayScaleFactor

            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2

            width: slider.availableWidth
            height: implicitHeight
            radius: 2 * AppFramework.displayScaleFactor
            color: "#bdbebf"

            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: "#21be2b"
                radius: 2 * AppFramework.displayScaleFactor
            }


        }

        handle: Rectangle {
            implicitWidth: 26 * AppFramework.displayScaleFactor
            implicitHeight: 26 * AppFramework.displayScaleFactor

            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2

            visible: !slider.isEmpty

            radius: 13 * AppFramework.displayScaleFactor
            color: slider.pressed ? "#f0f0f0" : "#f6f6f6"
            border {
                color: "#bdbebf"
            }

            Text {
                anchors {
                    fill: parent
                }

                text: slider.value

                font {
                    family: xform.style.fontFamily
                    pointSize: 13 * xform.style.textScaleFactor
                }

                fontSizeMode: Text.Fit
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Text {
            anchors {
                left: parent.left
                bottom: parent.bottom
            }

            text: slider.from

            font {
                family: xform.style.fontFamily
                pointSize: 12
            }
        }

        Text {
            anchors {
                right: parent.right
                bottom: parent.bottom
            }

            text: slider.to
            horizontalAlignment: Text.AlignRight

            font {
                family: xform.style.fontFamily
                pointSize: 12
            }
        }
    }
    
    //--------------------------------------------------------------------------

    function setValue(value) {
        console.log("range setValue:", value, "bindElement:", JSON.stringify(bindElement));
        slider.isEmpty = XFormJS.isEmpty(value);
        slider.setValue(slider.isEmpty ? 0 : value);

        formData.setValue(bindElement, value);
    }

    //--------------------------------------------------------------------------

    function getAttributeValue(element, name, defaultValue) {
        var value = Number(element["@" + name]);

        if (!isFinite(value)) {
            return defaultValue;
        }

        return value;
    }

    //--------------------------------------------------------------------------
}
