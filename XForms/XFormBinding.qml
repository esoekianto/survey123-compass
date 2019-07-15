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

import "XForm.js" as XFormJS

QtObject {
    //--------------------------------------------------------------------------

    property XFormData formData

    property var element
    property string elementId

    // Standard attributes - https://en.wikibooks.org/wiki/XForms/Bind

    property string nodeset
    property string type

    // Required

    property bool requiredIsDynamic
    property bool isRequired


    // ReadOnly

    property bool readOnlyIsDynamic
    property bool isReadOnly

    // Calculation

    // Relevant

    property bool relevantIsDynamic

    // Constraint

    // Esri attributes

    property string esriFieldType
    //property int esriFieldLength
    property string esriFieldAlias

    //

    property var defaultValue

    //

    property bool debug: false

    //--------------------------------------------------------------------------

    readonly property string kTypeBarcode: "barcode"
    readonly property string kTypeDate: "date"
    readonly property string kTypeDateTime: "dateTime"
    readonly property string kTypeDecimal: "decimal"
    readonly property string kTypeGeoPoint: "geopoint"
    readonly property string kTypeGeoShape: "geoshape"
    readonly property string kTypeGeoTrace: "geotrace"
    readonly property string kTypeInt: "int"
    readonly property string kTypeString: "string"
    readonly property string kTypeTime: "time"

    //--------------------------------------------------------------------------

    readonly property string kBindAttributeRequired: "required"
    readonly property string kBindAttributeReadOnly: "readonly"
    readonly property string kBindAttributeRelevant: "relevant"

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!element) {
            console.log("Initializing null binding");

            element = {};

            return;
        }

        if (debug) {
            console.log("initializing binding element:", JSON.stringify(element, undefined, 2));
        }

        elementId = element["@id"] || "";
        nodeset = element["@nodeset"] || "";
        type = element["@type"] || "undefined";

        esriFieldType = element["@esri:fieldType"] || "";
        //esriFieldLength = Number(element["@esri:fieldLength"]);
        esriFieldAlias = element["@esri:fieldAlias"] || ""

        var requiredBinding = formData.boolBinding(element, kBindAttributeRequired);
        requiredIsDynamic = isDynamic(requiredBinding);
        isRequired = requiredBinding;

        var isReadOnlyBinding = formData.boolBinding(element, kBindAttributeReadOnly);
        readOnlyIsDynamic = isDynamic(isReadOnlyBinding);
        isReadOnly = isReadOnlyBinding;

        relevantIsDynamic = element["@" + kBindAttributeRelevant] > "";

        if (debug) {
            console.log("binding nodeset:", nodeset,
                        "readOnlyIsDynamic:", readOnlyIsDynamic,
                        "requiredIsDynamic:", requiredIsDynamic,
                        "relevantIsDynamic:", relevantIsDynamic);
        }
    }

    //--------------------------------------------------------------------------

    function isDynamic(value) {
        return typeof value === "function";
    }

    //--------------------------------------------------------------------------

    function isRequiredBinding() {
        return requiredIsDynamic ? Qt.binding(function() { return isRequired; }) : isRequired;
    }

    //--------------------------------------------------------------------------

    function isReadOnlyBinding() {
        return readOnlyIsDynamic ? Qt.binding(function() { return isReadOnly; }) : isReadOnly;
    }

    //--------------------------------------------------------------------------
}
