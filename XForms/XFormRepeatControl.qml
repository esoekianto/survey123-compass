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

import QtQml 2.11
import QtQuick 2.9
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "XForm.js" as XFormJS

Item {
    id: repeatControl

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding ? binding.element : {}

    property XFormCollapsibleGroupControl groupControl
    readonly property var labelControl: groupControl.labelControl
    readonly property string strippedLabel: labelControl ? labelControl.labelText.replace(/(<([^>]+)>)/ig, "") : "";
    property alias contentItems: itemsColumn

    property int rowCount: 0
    property int currentRow: -1
    property bool newRow: false


    property string nodeset
    readonly property string tableName: nodeset.split('/').pop();
    readonly property var repeatCountExpression: formElement["@jr:count"]
    property int repeatCount: -1
    property int calculatedRepeatCount
    readonly property bool hasRepeatCount: repeatCountExpression > ""

    property real buttonSize: 35 * AppFramework.displayScaleFactor

    //--------------------------------------------------------------------------

    property string appearance
    readonly property bool hasMinimalAppearance: XFormJS.contains(appearance, "minimal")

    //--------------------------------------------------------------------------

    readonly property var esriParameters: XFormJS.parseParameters(bindElement["@esri:parameters"]);
    readonly property bool allowAdds: XFormJS.toBoolean(esriParameters.allowAdds, true);
    readonly property bool allowUpdates: XFormJS.toBoolean(esriParameters.allowUpdates, false);
    readonly property bool allowDeletes: false;//XFormJS.toBoolean(esriParameters.allowDeletes, false);

    //--------------------------------------------------------------------------

    readonly property bool editMode: xform.reviewMode
    property int currentEditMode: formData.kEditModeAdd

    readonly property bool newFormData: xform.formData.editMode == xform.formData.kEditModeAdd
    readonly property bool newCurrentData: currentEditMode == xform.formData.kEditModeAdd

    readonly property bool canAdd: newFormData || allowAdds
    readonly property bool canUpdate: newCurrentData || allowUpdates
    readonly property bool canDelete: newCurrentData || allowDeletes

    property bool relevant: parent.relevant
    property bool editable: canUpdate // parent.editable

    readonly property var parentRepeatControl: XFormJS.findParent(groupControl, xform.kControlTypeRepeat);

    property bool isMinimal: hasMinimalAppearance || hasRepeatCount

    property bool debug: false

    //--------------------------------------------------------------------------

    signal rowAdded(int index)

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    height: childrenRect.height

    visible: !hasRepeatCount || repeatCount > 0 || (editMode && rowCount > 0)

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        console.log("repeatControl:", nodeset, "tableName:", tableName, "appearance:", appearance);
        console.log("allowAdds:", allowAdds, "allowUpdates:", allowUpdates, "allowDeletes:", allowDeletes);
        console.log("parentRepeatControl:", parentRepeatControl);
        if (parentRepeatControl) {
            console.log("parentRepeatControl tableName:", parentRepeatControl.tableName, "nodeset:", parentRepeatControl.nodeset);
        }

        if (bindElement["@relevant"]) {
            relevant = formData.relevantBinding(bindElement);
        }

        if (repeatCountExpression > "") {
            console.log("Binding repeatCount to:", repeatCountExpression);
            calculatedRepeatCount = formData.numberBinding(repeatCountExpression, "repeatCount");
        }

        if (hasRepeatCount) {
            groupControl.hidden = Qt.binding(function() { return hasMinimalAppearance && rowCount <= 0; });
            if (labelControl) {
                labelControl.collapsible = Qt.binding(function() { return rowCount > 0; });
            }
        }
    }


    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: "%1 tableName:%2".arg(AppFramework.typeOf(repeatControl, true)).arg(JSON.stringify(tableName))
    }

    //--------------------------------------------------------------------------

    Connections {
        target: xform

        onStatusChanged: {
            if (xform.status === xform.statusReady) {
                initialize();
            }
        }
    }

    //--------------------------------------------------------------------------

    Connections {
        target: parentRepeatControl

        onCurrentRowChanged: {
            console.log(logCategory, "parentRepeatControl.currentRow:", parentRepeatControl.currentRow);
        }

        onRowAdded: {
            console.log(logCategory, "Parent row:", index, "added tableName:", tableName);
            resetRow();
        }
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (debug) {
            console.log(logCategory, "onRelevantChanged relevant:", relevant, "rowCount:", rowCount, "currentRow:", currentRow);
        }

        if (!relevant) {
            if (debug) {
                console.log("Repeat not relevant tableName:", tableName);
            }

            formData.setTableRowIndex(tableName, undefined);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedRepeatCountChanged: {
        console.log(logCategory, "onCalculatedRepeatCountChanged:", calculatedRepeatCount);

        var _repeatCount;
        if (typeof calculatedRepeatCount === "number" && isFinite(calculatedRepeatCount) && calculatedRepeatCount >= 0) {
            _repeatCount = calculatedRepeatCount;
        } else {
            _repeatCount = 0;
        }

        if (canDelete && _repeatCount < rowCount) {
            console.log("Checking if rows to delete are empty");
            var allEmpty = true;
            for (var index = _repeatCount; index < rowCount; index++) {
                allEmpty = formData.isTableRowEmpty(tableName, index);
                if (!allEmpty) {
                    console.log("Non-empty row:", index);
                    break;
                }
            }

            if (allEmpty) {
                currentRow = -1;
                repeatCount = _repeatCount;
            }
        } else if ((!editMode || canAdd) && _repeatCount > rowCount) {
            console.log("Adding rows _repeatCount:", _repeatCount, "rowCount:", rowCount, "currentRow:", currentRow);
            formData.setTableRows(tableName, _repeatCount);
            repeatCount = _repeatCount;
        } else if (!editMode) {
            repeatCount = _repeatCount;
        }
    }

    //--------------------------------------------------------------------------

    onRepeatCountChanged: {
        console.log(logCategory, "onRepeatCountChanged:", repeatCount, "currentRow:", currentRow, "rowCount:", rowCount);

        formData.setTableRows(tableName, calculatedRepeatCount);

        if (repeatCount >= 0) {
            rowCount = repeatCount;
            if ((currentRow < 0 && rowCount > 0) || currentRow >= rowCount) {
                currentRow = 0;
            }
        } else {
            currentRow = -1;
        }
    }

    //--------------------------------------------------------------------------

    onCurrentRowChanged: {
        console.log(logCategory, "onCurrentRowChanged:", currentRow, "newRow:", newRow);
        formData.setTableRowIndex(tableName, currentRow);
    }

    //--------------------------------------------------------------------------

    Connections {
        target: formData

        onTableRowIndexChanged: {
            var isTarget = name === tableName;

            if (name > "" && name !== tableName) {
                //console.log("ignoring onTableRowIndexChanged target:", name, "!== this:", tableName, "rowIndex:", rowIndex);
                return;
            }

            console.log(logCategory, "onTableRowIndexChanged isTarget:", isTarget, "target:", JSON.stringify(name), "rowIndex:", rowIndex, "currentRow:", currentRow);

            var table = xform.schema.tableNodes[tableName];

            var values;
            var mode = 2;
            var reason = 1;

            if (rowIndex >= 0) {
                values = XFormJS.clone(formData.getTableRow(tableName, rowIndex, true));
                currentRow = rowIndex;

                if (!values && repeatCount) {
                    newRow = true;
                }

                if (debug) {
                    console.log(logCategory, "rowIndex:", rowIndex, "newRow:", newRow, "values:", JSON.stringify(values, undefined, 2));
                }
            } else {
                var rows = formData.getTableRows(tableName);

                if (debug) {
                    console.log(logCategory, "rows:", JSON.stringify(rows, undefined, 2), "instance:", JSON.stringify(formData.instance, undefined, 2));
                }

                var _rowCount = rows.length;
                var _currentRow  = _rowCount > 0 ? 0 : -1;

                if (_currentRow >= 0) {
                    values = XFormJS.clone(formData.getTableRow(tableName, _currentRow, true));
                }

                if (!values) {
                    values = XFormJS.clone(formData.schema.tableInstance(tableName));
                    reason = 2;
                    mode = 0;
                }

                rowCount = _rowCount;
                currentRow  = _currentRow;

                if (!rowCount && !isMinimal) {
                    if (debug) {
                        console.log(logCategory, "Adding row for non-minimal repeat");
                    }

                    newRow = true;
                    rowCount = 1;
                    currentRow = 0;
                }

                if (debug) {
                    console.log(logCategory, "rowIndex:", rowIndex, "rowCount:", rowCount, "currentRow:", currentRow);
                }
            }

            if (newRow) {
                console.log(logCategory, "New repeat currentRow:", currentRow);

                xform.setValues(table, {}, 2);
                xform.preloadValues(table);
                xform.setDefaultValues(table);
                //xform.setValues(table, undefined, 2);
                newRow = false;

                updateExpressions();
            } else {
                //var values = XFormJS.clone(formData.getTableRow(tableName, undefined, true));

                if (debug) {
                    console.log(logCategory, "Edit repeat currentRow:", currentRow, "values:", JSON.stringify(values, undefined, 2));
                }

                if (!(XFormJS.isNullOrUndefined(values) && isMinimal)) {
                    if (debug) {
                        console.log(logCategory, "Setting values for non-minimal repeat values:", JSON.stringify(values));
                    }

                    xform.setValues(table, values, mode, reason);
                }
            }

            //            formData.expressionsList.enabled = true;
            //            formData.expressionsList.updateExpressions();

            var data = formData.getTableRow(tableName, undefined, isMinimal);

            currentEditMode = formData.metaValue(data || {}, formData.kMetaEditMode, formData.kEditModeAdd);

            if (debug) {
                console.log(logCategory, "currentEditMode:", currentEditMode, "data:", JSON.stringify(data, undefined, 2));
            }
        }
    }

    //--------------------------------------------------------------------------

    function resetRow() {
        console.log(logCategory, "Resetting row currentRow:", currentRow);
        var table = xform.schema.tableNodes[tableName];
        xform.setValues(table, {}, 2);
        xform.preloadValues(table);
        xform.setDefaultValues(table);
        updateExpressions();//formData.expressionsList.updateExpressions();

        rowAdded(currentRow);
    }

    //--------------------------------------------------------------------------
    
    Column {
        id: layout

        width: parent.width
        spacing: 5 * AppFramework.displayScaleFactor

        XFormGroupBox {
            width: parent.width

            visible: hasRepeatCount && rowCount != calculatedRepeatCount
            flat: true

            border {
                color: rowCount > calculatedRepeatCount
                       ? xform.style.deleteIconColor
                       : canAdd
                         ? xform.style.iconColor
                         : xform.style.requiredColor
            }

            ColumnLayout {

                width: parent.width
                spacing: 2 * AppFramework.displayScaleFactor

                XFormText {
                    Layout.fillWidth: true

                    visible: !canAdd && rowCount < calculatedRepeatCount
                    text: qsTr("Expected records: %1").arg(calculatedRepeatCount)
                    color: xform.style.requiredColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }

                XFormText {
                    Layout.fillWidth: true

                    visible: !canDelete && rowCount > calculatedRepeatCount
                    text: qsTr("Maximum records exceeded: %1").arg(calculatedRepeatCount)
                    color: xform.style.requiredColor
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    horizontalAlignment: Text.AlignHCenter
                }

                RowLayout {
                    Layout.fillWidth: true

                    visible: canAdd && rowCount < calculatedRepeatCount
                    spacing: 5 * AppFramework.displayScaleFactor

                    XFormImageButton {
                        id: addRecordsButton

                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: buttonSize

                        source: "images/add.png"

                        onClicked: {
                            action();
                        }

                        function action() {
                            forceActiveFocus();
                            addRows(calculatedRepeatCount - rowCount);
                        }
                    }

                    XFormText {
                        Layout.fillWidth: true

                        text: qsTr("Add records: %1").arg(calculatedRepeatCount - rowCount)
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                addRecordsButton.action();
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    visible: canDelete && rowCount > calculatedRepeatCount
                    spacing: 5 * AppFramework.displayScaleFactor

                    XFormImageButton {
                        id: deleteRecordsButton

                        Layout.preferredWidth: buttonSize
                        Layout.preferredHeight: buttonSize

                        source: "images/trash.png"
                        color: xform.style.deleteIconColor

                        onClicked: {
                            action();
                        }

                        function action() {
                            forceActiveFocus();
                            confirmDeleteRows(rowCount - calculatedRepeatCount);
                        }
                    }

                    XFormText {
                        Layout.fillWidth: true

                        text: calculatedRepeatCount > 0
                              ? qsTr("Delete last records: %1").arg(rowCount - calculatedRepeatCount)
                              : qsTr("Delete all records")
                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere

                        MouseArea {
                            anchors.fill: parent

                            onClicked: {
                                deleteRecordsButton.action();
                            }
                        }
                    }
                }
            }
        }

        Column {
            id: itemsColumn

            readonly property bool relevant: repeatControl.relevant && (rowCount > 0 || (editMode && hasRepeatCount))
            readonly property bool editable: repeatControl.editable
            readonly property alias repeatControl: repeatControl

            spacing: 5 * AppFramework.displayScaleFactor
            width: parent.width
            visible: rowCount > 0

            onRelevantChanged: {
                console.log(logCategory, "onRelevantChanged relevant:", relevant);
            }
        }

        RowLayout {
            visible: hasRepeatCount
            width: parent.width
            spacing: 5 * AppFramework.displayScaleFactor

            Item {
                Layout.fillWidth: true
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/next.png"
                enabled: currentRow > 0 && rowCount > 0
                visible: enabled
                rotation: 180

                onClicked: {
                    gotoPreviousRow(this);
                }

                onPressAndHold: {
                    gotoFirstRow(this);
                }
            }

            Text {
                visible: rowCount > 0
                text: (debug ? "%1: ".arg(tableName) : "") + qsTr("%1 of %2").arg(currentRow + 1).arg(rowCount)
                color: xform.style.groupLabelColor
                font {
                    pointSize: xform.style.groupLabelPointSize * 0.75
                    family: xform.style.groupLabelFontFamily
                }

                MouseArea {
                    anchors.fill: parent

                    //enabled: debug

                    onPressAndHold: {
                        debug = !debug;
                        formData.logInstance(tableName);
                    }
                }
            }

            XFormImageButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                source: "images/next.png"
                enabled: currentRow < (rowCount - 1)
                visible: enabled

                onClicked: {
                    gotoNextRow(this);
                }

                onPressAndHold: {
                    gotoLastRow(this);
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Item {
            visible: !hasRepeatCount
            width: parent.width
            height: childrenRect.height + layout.spacing

            RowLayout {
                y: layout.spacing
                width: parent.width
                spacing: 5 * AppFramework.displayScaleFactor

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/trash.png"
                    enabled: rowCount > 0 && canDelete
                    visible: enabled
                    color: xform.style.deleteIconColor

                    onClicked: {
                        forceActiveFocus();
                        confirmDeleteCurrentRow();
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/next.png"
                    rotation: 180
                    enabled: rowCount > 0 && currentRow > 0
                    visible: enabled

                    onClicked: {
                        gotoPreviousRow(this);
                    }

                    onPressAndHold: {
                        gotoFirstRow(this);
                    }
                }

                Text {
                    visible: rowCount > 0
                    text: (debug ? "%1: ".arg(tableName) : "") + qsTr("%1 of %2").arg(currentRow + 1).arg(rowCount)
                    color: xform.style.groupLabelColor
                    font {
                        pointSize: xform.style.groupLabelPointSize * 0.75
                        family: xform.style.groupLabelFontFamily
                    }

                    MouseArea {
                        anchors.fill: parent

                        //enabled: debug

                        onPressAndHold: {
                            debug = !debug;
                            formData.logInstance(tableName);
                        }
                    }
                }

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/next.png"
                    enabled: rowCount > 0 && currentRow < (rowCount - 1)
                    visible: enabled

                    onClicked: {
                        gotoNextRow(this);
                    }

                    onPressAndHold: {
                        gotoLastRow(this);
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                XFormImageButton {
                    Layout.preferredWidth: buttonSize
                    Layout.preferredHeight: buttonSize

                    source: "images/add.png"
                    enabled: canAdd
                    visible: enabled

                    onClicked: {
                        ensureVisible();
                        forceActiveFocus();
                        addRow();
                    }
                }
            }
        }
    }

    Component {
        id: confirmPanel

        XFormConfirmPanel {
            icon: "images/trash.png"
            iconColor: xform.style.deleteIconColor
        }
    }

    //--------------------------------------------------------------------------

    function initialize() {
        console.log(logCategory, "initialize repeatControl bindElement:", JSON.stringify(bindElement), "isMinimal:", isMinimal, "rowCount:", rowCount, "currentRow:", currentRow);

        if (!isMinimal && rowCount < 1) {
            console.log(logCategory, "Adding initial repeat");

            addRow();
            formData.setTableRowIndex(tableName, currentRow);
        }
    }

    //--------------------------------------------------------------------------

    function ensureVisible() {
        ensureItemVisible(groupControl);
    }

    //--------------------------------------------------------------------------

    function gotoRow(actionItem, rowIndex, moveToTop) {
        if (actionItem) {
            actionItem.forceActiveFocus();
        } else {
            console.error("goto actionItem null");
            console.trace();
        }

        if (!validateCurrentRow()) {
            return;
        }

        setCurrentRow(rowIndex);

        if (moveToTop) {
            ensureVisible();
        }
    }

    //--------------------------------------------------------------------------

    function gotoFirstRow(actionItem, moveToTop) {
        gotoRow(actionItem, 0, moveToTop);
    }

    //--------------------------------------------------------------------------

    function gotoPreviousRow(actionItem, moveToTop) {
        gotoRow(actionItem, currentRow - 1, moveToTop);
    }

    //--------------------------------------------------------------------------

    function gotoNextRow(actionItem, moveToTop) {
        gotoRow(actionItem, currentRow + 1, moveToTop);
    }

    //--------------------------------------------------------------------------

    function gotoLastRow(actionItem, moveToTop) {
        gotoRow(actionItem, rowCount - 1, moveToTop);
    }

    //--------------------------------------------------------------------------

    function addRow() {
        console.log(arguments.callee.name, "rowCount:", rowCount, "currentRow:", currentRow);
        if (rowCount > 0) {
            if (!validateCurrentRow()) {
                return;
            }
        }

        newRow = true;
        rowCount++;
        formData.getTableRow(tableName, rowCount - 1);
        setCurrentRow(rowCount - 1);
        rowAdded(currentRow);
    }

    //--------------------------------------------------------------------------

    function addRows(count) {
        console.log(arguments.callee.name, count, "rowCount:", rowCount, "currentRow:", currentRow);

        if (rowCount > 0) {
            if (!validateCurrentRow()) {
                return;
            }
        }

        newRow = true;
        var newRowIndex = rowCount;
        rowCount += count;
        formData.setTableRows(tableName, rowCount);
        setCurrentRow(newRowIndex);
    }

    //--------------------------------------------------------------------------

    function validateCurrentRow() {
        var table = formData.schema.tableNodes[tableName];
        var data = formData.getTableRow(tableName);

        var error = formData.validateData(table, data);
        if (error) {
            xform.validationError(error);
            return false;
        }

        return true;
    }

    //--------------------------------------------------------------------------

    function setCurrentRow(rowIndex) {
        console.log(logCategory, arguments.callee.name, rowIndex);
        currentRow = rowIndex;
    }

    //--------------------------------------------------------------------------

    function confirmDeleteCurrentRow() {
        var panel = confirmPanel.createObject(app, {
                                                  title: qsTr("Confirm Delete"),
                                                  text: strippedLabel,
                                                  question: qsTr("Are you sure you want to delete %1 of %2?").arg(currentRow + 1).arg(rowCount)
                                              });

        panel.show(deleteCurrentRow, undefined);
    }

    function deleteCurrentRow() {
        console.log(arguments.callee.name, "rowCount:", rowCount, "currentRow:", currentRow);

        if (!isMinimal && rowCount == 1) {
            console.log("Deleting last row in non-minimal repeat");
            isMinimal = true;
        }

        if (!formData.deleteTableRow(tableName, currentRow)) {
            console.log("deleteCurrentRow failed:", currentRow);

            if (currentRow === 0 && rowCount === 1 && !isMinimal) {
                console.log("deleting initial row");
                rowCount = 0;
            }

            return;
        }

        rowCount = formData.getTableRows(tableName).length;

        if (rowCount === 0) {
            currentRow = -1;
        }

        console.log("row deleted rowCount:", rowCount, "currentRow:", currentRow);
    }

    //--------------------------------------------------------------------------

    function confirmDeleteRows(count) {
        var panel = confirmPanel.createObject(app, {
                                                  title: qsTr("Confirm Delete"),
                                                  text: strippedLabel,
                                                  question: rowCount === count
                                                            ? qsTr("Are you sure you want to delete all records?")
                                                            : qsTr("Are you sure you want to delete the last records: %1 ?").arg(count)
                                              });

        panel.show(function () { deleteRows(count); }, undefined);
    }

    function deleteRows(count) {
        console.log(arguments.callee.name, count);

        var deleteAll = rowCount === count;

        console.log("row delete rowCount:", rowCount, "currentRow:", currentRow, "deleteAll:", deleteAll);

        if (deleteAll) {
            if (!isMinimal) {
                console.log("Deleting all rows in non-minimal repeat");
                isMinimal = true;
            }

            rowCount = 0;
            formData.setTableRows(tableName, rowCount);
            currentRow = -1;
        } else {

            var index = rowCount - 1;
            while (count--) {
                if (!formData.deleteTableRow(tableName, index)) {
                    console.log("deleteTableRow failed:", index);
                }
                index--;
            }

            rowCount = formData.getTableRows(tableName).length;

            console.log("getTableRows.length:", rowCount);

            if (rowCount === 0) {
                currentRow = -1;
            } else if (currentRow >= rowCount) {
                setCurrentRow(rowCount - 1);
            }
        }

        console.log(logCategory, "rows deleted rowCount:", rowCount, "currentRow:", currentRow);
    }

    //--------------------------------------------------------------------------

    function updateExpressions() {
        var table = xform.schema.tableNodes[tableName];
        var expressions = formData.expressionsList.expressions;

        console.log(logCategory, arguments.callee.name, "#fields:", table.fields.length);

        table.fields.forEach(function (field) {
            expressions.forEach(function (expression) {
                if (expression.thisNodeset === field.nodeset) {
                    if (debug) {
                        console.log(logCategory, "expressions match field:", field.name, "purpose:", expression.purpose, "expression:", expression.expression);
                    }
                    expression.trigger();
                }
            });
        });
    }

    //--------------------------------------------------------------------------
}
