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
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS

XFormGroupBox {
    id: groupBox

    property bool isPage: false
    property var formElement
    property XFormData formData
    property XFormBinding binding

    property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property alias headerItems: headerColumn
    property alias contentItems: itemsColumn

    property bool hidden: false

    property var labelControl
    property var hintControl

    readonly property bool collapsed: labelControl && typeof labelControl.collapsed === "boolean" ? labelControl.collapsed : false
    readonly property string labelText: labelControl ? labelControl.labelText : ""

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    flat: isPage
    visible: relevant && !hidden
    //title: text

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        var bindElement = binding ? binding.element : {};
        if (formData && bindElement["@relevant"]) {
            relevant = formData.relevantBinding(bindElement);
        }

        var esriStyle = XFormJS.parseParameters(formElement["@esri:style"]);

        if (esriStyle.backgroundColor > "") {
            backgroundColor = esriStyle.backgroundColor;
        }
    }

    //--------------------------------------------------------------------------

    Column {
        anchors {
            left: parent.left
            right: parent.right
        }

        spacing: 5 * AppFramework.displayScaleFactor

        Column {
            id: headerColumn

            anchors {
                left: parent.left
                right: parent.right
            }

            spacing: parent.spacing
        }

        Column {
            id: itemsColumn

            readonly property alias relevant: groupBox.relevant
            readonly property alias editable: groupBox.editable

            anchors {
                left: parent.left
                right: parent.right
            }

            spacing: parent.spacing
            visible: !collapsed
            enabled: binding ? !binding.isReadOnly : true
        }
    }

    //--------------------------------------------------------------------------

    function collapse(collapsed) {
        if (typeof collapsed !== "boolean") {
            collapsed = true;
        }

        if (labelControl) {
            labelControl.collapsed = collapsed;
        }
    }

    //--------------------------------------------------------------------------
}
