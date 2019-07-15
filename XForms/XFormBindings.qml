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

Item {
    id: bindingsItem

    //--------------------------------------------------------------------------

    property XFormData formData
    property var bindings: []

    readonly property var nullBinding: null

    property bool debug: false

    //--------------------------------------------------------------------------

    function initialize(bindArray, defaultInstance) {
        if (!Array.isArray(bindArray)) {
            console.warn("No bind array")
            return;
        }

        console.log("Creating bindings:", bindArray.length);

        bindArray.forEach(function (bind) {
            var nodesetPath = XFormJS.replaceAll(bind["@nodeset"], "/", ".").substring(1);
            var defaultValue = XFormJS.getPropertyPathValue(defaultInstance, nodesetPath);

            if (debug) {
                console.log("nodesetPath:", nodesetPath, "defaultValue:", defaultValue);
            }

            var binding = bindingComponent.createObject(bindingsItem,
                                                        {
                                                            formData: formData,
                                                            element: bind,
                                                            defaultValue: defaultValue,
                                                            debug: debug
                                                        });

            bindings.push(binding);
        });

        console.log("Bindings created:", bindings.length);
    }

    //--------------------------------------------------------------------------

    function findByNodeset(nodeset) {
        if (!nodeset) {
            return nullBinding;
        }

        var binding = bindings.find(function(binding) {
            return binding.nodeset === nodeset;
        });

        if (!binding) {
            console.log("No binding for nodeset:", nodeset);
            return nullBinding;
        }

        return binding;
    }

    //--------------------------------------------------------------------------

    Component {
        id: bindingComponent

        XFormBinding {
            debug: bindingsItem.debug
        }
    }

    //--------------------------------------------------------------------------

    XFormBinding {
        // id: nullBinding
    }

    //--------------------------------------------------------------------------
}

