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
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS
//import "singletons" 1.0

Item {

    id: xformControl

    property var binding
    property XFormData formData
    property var formElement

    property var appearance: formElement ? formElement["@appearance"] : null // formElement ? formElement[XFormConstants.kAttribute_Appearance] : null
    property var constraint
    property bool readOnly: !editable || binding["@readonly"] === "true()" // binding[XFormConstants.kAttribute_ReadOnly] === "true()"

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated
    property bool initialized: false

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    width: parent.width
    height: childrenRect.height

    Component.onCompleted: {
        console.log("--------------",JSON.stringify(formElement));
    }

    // END /////////////////////////////////////////////////////////////////////

    //    formElement --> json.body[input][x]
    //    {
    //        "#nodes": [
    //            "label"
    //        ],
    //        "@ref": "/_form_cool_name/front_area",
    //        "label": "Front Area"
    //    }

    //    binding --> json.model.bind[x]
    //    {
    //        "@nodeset": "/_form_cool_name/front_area",
    //        "@type": "decimal",
    //        "@calculate": "(/_form_cool_name/side_length) * (/_form_cool_name/side_width))"
    //    }

}
