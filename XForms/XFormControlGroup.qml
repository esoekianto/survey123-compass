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

XFormGroupBox {
    id: groupBox

    property XFormBinding binding
    property XFormData formData

    property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property alias contentItems: itemsColumn

    property var labelControl
    property var hintControl

    property bool valid: true
    property string errorMessage
    readonly property bool inlineErrorMessages: xform.inlineErrorMessages

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    implicitWidth: parent.width

    visible: relevant


    border {
        width: (valid || !inlineErrorMessages) ? 0 : 1 * AppFramework.displayScaleFactor;
        color: (valid || !inlineErrorMessages) ? "transparent" : style.requiredColor;
    }

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var bindElement = binding ? binding.element : {};
        if (formData && bindElement["@relevant"]) {
            relevant = formData.relevantBinding(bindElement);
        }
    }

    //--------------------------------------------------------------------------

    Column {
        id: itemsColumn

        readonly property alias relevant: groupBox.relevant
        readonly property alias editable: groupBox.editable

        anchors {
            left: parent.left
            right: parent.right
        }

        spacing: 5 * AppFramework.displayScaleFactor

        Loader {
            anchors {
                left: parent.left
                right: parent.right
                margins: - groupBox.padding
            }

            active: !valid && errorMessage > "" && inlineErrorMessages
            visible: active

            sourceComponent: errorMessageComponent
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: errorMessageComponent

        Item {
            height: layout.height

            Rectangle {
                anchors {
                    fill: parent
                    topMargin: - groupBox.padding
                }

                color: style.requiredColor

                RowLayout {
                    id: layout

                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        margins: groupBox.padding
                    }

                    Text {
                        Layout.fillWidth: true

                        text: errorMessage
                        color: "#fefefe"
                        font {
                            family: xform.style.fontFamily
                            bold: xform.style.boldText
                            pointSize: 14 * xform.style.textScaleFactor
                        }
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------
}
