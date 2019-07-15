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
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3
import QtMultimedia 5.5
import QtSensors 5.0 //compass bearing

import ArcGIS.AppFramework 1.0
import ArcGIS.AppFramework.Controls 1.0

import "XForm.js" as XFormJS
import "Calculator"


RowLayout {
    id: inputLayout

    property var formElement
    property XFormBinding binding
    property XFormData formData

    readonly property var bindElement: binding.element

    property var constraint
    property var calculatedValue

    property int changeReason: 0 // 1=User, 2=setValue, 3=Calculated

    property alias currentValue: textField.text
    readonly property bool showCalculate: !isReadOnly && changeReason === 1 && calculatedValue !== undefined && !isEqual(calculatedValue, currentValue)

    readonly property bool relevant: parent.relevant
    readonly property bool editable: parent.editable

    property bool valid: true
    property string errorMessage
    property XFormControlGroup controlGroup: XFormJS.findParent(this, undefined, "XFormControlGroup")

    property string emptyText
    property var appearance: (formElement ? formElement["@appearance"] : "") || ""
    property bool showCharacterCount: binding.type === binding.kTypeString || isBarcode

    readonly property bool isBarcode: binding.type === binding.kTypeBarcode
    readonly property bool isReadOnly: !editable || binding.isReadOnly
    readonly property bool showSpinners: appearance.indexOf("spinner") >= 0 && !isReadOnly
    //compass bearing
    readonly property bool showBearing : appearance.indexOf("bearing") >= 0

    property real spinnerScale: 2
    property real spinnerMargin: 15 * AppFramework.displayScaleFactor

    property int barcodeButtonSize: 40 * AppFramework.displayScaleFactor

    property Loader keypadLoader

    readonly property var numberLocale: xform.numberLocale
    property string valueType
    property var currentTypedValue

    property bool debug: false

    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    layoutDirection: xform.languageDirection

    //--------------------------------------------------------------------------

    signal cleared();

    //--------------------------------------------------------------------------

    Component.onCompleted: {
        if (!isReadOnly) {
            if (appearance.indexOf("numbers") >= 0) {
                keypadLoader = numbersKeypad.createObject(parent);
            } else if (appearance.indexOf("calculator") >= 0) {
                keypadLoader = calculatorKeypad.createObject(parent);
            //compass bearing
            } else if (appearance.indexOf("bearing") >= 0) {
                keypadLoader = bearingKeypad.createObject(parent);
            }
        }

        controlGroup.valid = Qt.binding(function () { return valid; });
        controlGroup.errorMessage = Qt.binding(function () { return errorMessage; });
    }

    //--------------------------------------------------------------------------
    // Clear values when not relevant

    onRelevantChanged: {
        if (relevant) {
            setValue(binding.defaultValue);
            formData.triggerCalculate(bindElement);
        } else {
            valid = true;
            setValue(undefined, 3);
        }
    }

    //--------------------------------------------------------------------------

    onCalculatedValueChanged: {
        if (relevant && formData.changeBinding !== bindElement && changeReason !== 1) {
            setValue(calculatedValue, 3);
            calculateButtonLoader.active = true;
        }
    }

    //--------------------------------------------------------------------------

    onCleared: {
        valid = true;
        setValue(undefined, 1);
    }

    //--------------------------------------------------------------------------

    onNumberLocaleChanged: {
        if (debug) {
            console.log("onNumberLocaleChanged:", numberLocale.name);
        }

        if (!XFormJS.isNullOrUndefined(currentTypedValue)) {
            currentValue = valueToText(currentTypedValue);
        }
    }

    //--------------------------------------------------------------------------

    onCurrentValueChanged: {
        var value = textToValue(currentValue, Number.NEGATIVE_INFINITY);
        if (value === Number.NEGATIVE_INFINITY) {
            currentTypedValue = undefined;
            valid = currentValue == "";
        } else {
            currentTypedValue = value;
            valid = true;
        }
    }

    //--------------------------------------------------------------------------

    LoggingCategory {
        id: logCategory

        name: AppFramework.typeOf(inputLayout, true)
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredHeight: textField.height
        Layout.preferredWidth: Layout.preferredHeight * spinnerScale
        Layout.rightMargin: spinnerMargin

        sourceComponent: spinnerButtonComponent
        //compass bearing
        active: showSpinners || showBearing
        visible: showSpinners || showBearing

        onLoaded: {
            item.step = -1;
        }
    }

    //--------------------------------------------------------------------------
    //XFormTextField {
    TextField {
        id: textField

        Layout.fillWidth: true

        readOnly: isReadOnly
        visible: !isBarcode || (isBarcode && appearance !== "minimal")

        style: XFormTextFieldStyle {
            style: xform.style
            valid: inputLayout.valid
            altTextColor: changeReason === 3
        }

        Component.onCompleted: {
            var fieldLength = 255;
            var imh = Qt.ImhNone;
            valueType = typeof "";

            switch (binding.type) {
            case binding.kTypeString:
                if (Qt.platform.os === "android") {
                    imh |= Qt.ImhNoPredictiveText;
                }
                if (appearance.indexOf("nopredictivetext") >= 0) {
                    imh |= Qt.ImhNoPredictiveText;
                } else if (appearance.indexOf("predictivetext") >= 0) {
                    imh &= ~Qt.ImhNoPredictiveText;
                }
                break;

            case binding.kTypeInt:
                if (Qt.platform.os === "ios") {
                    imh = Qt.ImhPreferNumbers;
                } else {
                    imh = Qt.ImhDigitsOnly;
                }
                validator = intValidatorComponent.createObject(this);
                fieldLength = 9;
                valueType = typeof 0;
                break;

            case binding.kTypeDecimal:
                if (Qt.platform.os === "ios") {
                    imh = Qt.ImhPreferNumbers;
                } else {
                    imh = Qt.ImhFormattedNumbersOnly;
                }
                validator = doubleValidatorComponent.createObject(this);
                valueType = typeof 0;
                break;

            case binding.kTypeDate:
                imh = Qt.ImhDate;
                break;

            case binding.kTypeTime:
                imh = Qt.ImhTime;
                validator = timeValidatorComponent.createObject(this);
                placeholderText = "hh:mm:ss";
                break;

            case binding.kTypeDateTime:
                imh = Qt.ImhDate | Qt.ImhTime;
                break;

            case binding.kTypeBarcode:
                imh = Qt.ImhNoPredictiveText;
                break;

            default:
                console.log("Unhandled input bind type:", binding.type);
                break;
            }

            var esriProperty = bindElement["@esri:fieldLength"];
            if (esriProperty > "") {
                var n = Number(esriProperty);
                if (isFinite(n)) {
                    fieldLength = n;
                }
            }

            if (fieldLength > 0) {
                maximumLength = fieldLength;
            }

            var mask = formElement["@esri:inputMask"];
            if (mask > "") {
                textField.inputMask = mask;
                imh |= Qt.ImhNoPredictiveText;
            }

            inputMethodHints = imh;

            constraint = formData.createConstraint(this, bindElement);

            if (bindElement["@calculate"]) {

            }
            //compass bearing
            if (showSpinners || showBearing) {
                horizontalAlignment = TextInput.AlignHCenter;
            }
        }

        onAcceptableInputChanged: {
            if (!acceptableInput && validator && validator.invalidMessage && binding.isRequired) {
                errorMessage = validator.invalidMessage;
            }
        }

        onInputMaskChanged: {
            emptyText = text;
            //console.log("emptyText:", JSON.stringify(emptyText));
        }

        onEditingFinished: {
            var value;
            var validate = false;

            if (text > "") {
                validate = true;

                switch (binding.type) {
                case binding.kTypeInt:
                    value = XFormJS.numberFromLocaleString(numberLocale, text);
                    break;

                case binding.kTypeDecimal:
                    value = XFormJS.numberFromLocaleString(numberLocale, text);
                    break;

                case binding.kTypeDate:
                case binding.kTypeDateTime:
                    break;

                default:
                    value = text;
                    break;
                }
            }

            formData.setValue(bindElement, value);

            if (validate && constraint && relevant) {
                var error = constraint.validate();
                if (error) {
                    valid = false;
                    errorMessage = error.message;
                    if (!controlGroup.inlineErrorMessages) {
                        xform.validationError(error);
                    }
                } else {
                    valid = true;
                    errorMessage = "";
                }
            }
        }

        onLengthChanged: {
            if (length === 0) {
                formData.setValue(bindElement, undefined);
            } else if (!readOnly){
                clearButtonLoader.active = true;
            }
        }

        onActiveFocusChanged: {
            if (activeFocus && keypadLoader) {
                keypadLoader.showKeypad = true;
            }

            if (!activeFocus) {
                var error = validateInput();
                if (error) {
                    valid = false;
                    errorMessage = error.message;
                }
            }

            xform.controlFocusChanged(this, activeFocus, bindElement);
        }

        Keys.onPressed: {
            if (!readOnly) {
                changeReason = 1;
            }
        }

        XFormInputCharacterCount {
            anchors {
                top: parent.bottom
                right: parent.right
            }

            enabled: showCharacterCount && parent.inputMask === ""
        }

        Loader {
            anchors.fill: parent
            active: textField.inputMask > ""

            sourceComponent: MouseArea {
                acceptedButtons: Qt.LeftButton
                propagateComposedEvents: true

                onPressed: {
                    //console.log("Input mask active:", textField.inputMask, "text:", JSON.stringify(currentValue), "empty:", JSON.stringify(emptyText));

                    if (currentValue == emptyText) {
                        textField.cursorPosition = 0;
                        textField.forceActiveFocus();
                    } else {
                        mouse.accepted = false;
                    }
                }
            }
        }

        Loader {
            id: clearButtonLoader

            property real clearButtonMargin: clearButtonLoader.width + clearButtonLoader.anchors.margins * 1.5
            property int textDirection: textField.length > 0 ? textField.isRightToLeft(0, textField.length) ? Qt.RightToLeft : Qt.LeftToRight : layoutDirection
            property real endMargin: textField.__contentHeight / 3

            onTextDirectionChanged: {
                anchors.left = undefined;
                anchors.right = undefined;

                if (textDirection == Qt.RightToLeft) {
                    anchors.left = parent.left;
                } else {
                    anchors.right = parent.right;
                }
            }

            anchors {
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: 2 * AppFramework.displayScaleFactor
            }

            visible: parent.text > "" && !parent.readOnly
            width: height
            active: false

            sourceComponent: ImageButton {
                source: "images/clear.png"
                glowColor: "transparent"
                hoverColor: "transparent"
                pressedColor: "transparent"

                onClicked: {
                    cleared();
                }
            }

            onVisibleChanged: {
                if (parent.__panel) {
                    parent.__panel.rightMargin = Qt.binding(function() { return visible && textDirection == Qt.LeftToRight ? clearButtonMargin : endMargin; });
                    parent.__panel.leftMargin = Qt.binding(function() { return visible && textDirection == Qt.RightToLeft ? clearButtonMargin : endMargin; });
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: intValidatorComponent

        IntValidator {
            property string invalidMessage: qsTr("Invalid integer value")

            locale: numberLocale.name
        }
    }

    Component {
        id: doubleValidatorComponent

        DoubleValidator {
            property string invalidMessage: qsTr("Invalid number value")

            notation: DoubleValidator.StandardNotation
            locale: numberLocale.name
        }
    }

    Component {
        id: timeValidatorComponent

        RegExpValidator {
            property string invalidMessage: qsTr("Invalid time value")

            regExp: /^[0-9][0-9]:[0-5][0-9]:[0-5][0-9]$/
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        Layout.preferredHeight: textField.height
        Layout.preferredWidth: Layout.preferredHeight * spinnerScale
        Layout.leftMargin: spinnerMargin

        sourceComponent: spinnerButtonComponent
        active: showSpinners || showBearing
        visible: showSpinners || showBearing
    }

    Component {
        id: spinnerButtonComponent

        Rectangle {
            id: spinnerButton

            property double step: 1
            property bool playSound: false
            property url soundSource: "audio/" + (step < 0 ? "click-down.mp3" : "click-up.mp3")
            property int repeatCount: 0

            signal clicked
            signal repeat

            color: mouseArea.pressed ? border.color : xform.style.keyColor
            border {
                width: 1
                color: xform.style.keyBorderColor
            }
            radius: height / 2 //* 0.16

            onClicked: {
                //textField.forceActiveFocus();
                spinValue(playSound);
            }

            onRepeat: {
                repeatCount++;
                spinValue(playSound && repeatCount == 1);
            }

            function spinValue(sound) {
                if (sound) {
                    if (audio.playbackState === Audio.PlayingState) {
                        audio.stop();
                    }

                    audio.play();
                }

                var textValue = currentValue;
                var stepValue = step;
                var precision;
                var decimalPointIndex = textValue.indexOf(numberLocale.decimalPoint);
                if (decimalPointIndex >= 0) {
                    precision = textValue.length - decimalPointIndex - 1;
                    if (precision > 0) {
                        stepValue = Math.pow(10, -precision) * step;
                    }
                }

                var value = XFormJS.numberFromLocaleString(numberLocale, textValue);
                if (!isFinite(value)) {
                    value = 0;
                }
                value += stepValue;
                setValue(value, 1);

                if (precision > 0) {
                    currentValue = value.toLocaleString(numberLocale, "", precision);
                }
            }

            Text {
                anchors {
                    centerIn: parent
                    verticalCenterOffset: -paintedHeight * 0.05
                }

                text: step > 0 ? "+" : "-"
                color: xform.style.keyTextColor
                styleColor: xform.style.keyStyleColor
                style: Text.Raised

                font {
                    bold: true
                    pixelSize: parent.height * 0.8
                    family: xform.style.keyFontFamily
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent

                onClicked: {
                    spinnerButton.clicked();
                }

                onPressAndHold: {
                    repeatCount = 0;
                    repeatTimer.start();
                }

                onReleased: {
                    repeatTimer.stop();
                }

                onExited: {
                    repeatTimer.stop();
                }

                onCanceled: {
                    repeatTimer.stop();
                }
            }

            Audio {
                id: audio

                autoLoad: false
                source: spinnerButton.soundSource
            }

            Timer {
                id: repeatTimer

                running: false
                interval: 100
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    spinnerButton.repeat();
                }
            }
        }
    }

    //--------------------------------------------------------------------------
    //compass Bearing
    Component {
        id: bearingKeypad

        Loader {
            property bool showKeypad: true

            width: parent.width
            height: visible ? (textField.height + AppFramework.displayScaleFactor * 5) * 4 * 1.2  : 0 //150 * AppFramework.displayScaleFactor * xform.style.scale : 0
            active: true //textField.activeFocus && showKeypad
            visible: true //active


            onActiveChanged: {
                if (active) {
                    Qt.inputMethod.hide();
                }
            }

            onLoaded: {
                xform.ensureItemVisible(inputLayout.parent.parent);
            }

            sourceComponent: Item {

                Rectangle{
                    id: myCanvas
                    anchors.fill: parent
                    Image {
                        id: bk
                        fillMode: Image.PreserveAspectFit
                        height: 150  * AppFramework.displayScaleFactor
                        width: 150  * AppFramework.displayScaleFactor
                        anchors.centerIn: parent
                        source: "images/BK_Mono.png"
                    }
                    Image {
                        id: north
                        fillMode: Image.PreserveAspectFit
                        height: 150  * AppFramework.displayScaleFactor
                        width: 150  * AppFramework.displayScaleFactor
                        anchors.centerIn: parent
                        source: "images/North.png"

                        rotation: textField.text
                    }
                    Compass {
                        id: myCompass
                        active: false
                        onReadingChanged: {
                            textField.text = myCompass.reading.azimuth
                        }
                    }
                    MouseArea{
                        anchors.fill: myCanvas
                        onClicked: {
                            var myX = mouseX
                            if (myX>myCanvas.width/2){
                                myX=mouseX-(myCanvas.width/2)
                            }else{
                                myX=((myCanvas.width/2) - mouseX)*-1
                            }

                            var myY = mouseY
                            if (myY>myCanvas.height/2){
                                myY=(mouseY-(myCanvas.height/2))*-1
                            }else{
                                myY=(myCanvas.height/2)-mouseY
                            }
                            var angleArit = Math.atan2(myY,myX)* (180/Math.PI)
                            var angleGeo = (450-angleArit) % 360

                            if((binding["@type"] === "int")){
                                textField.text = Math.round(angleGeo)
                            }else{
                                textField.text = Math.round(angleGeo*100)/100
                            }
                        }
                        onPressAndHold: {
                            myCompass.active=true
                        }
                        onReleased: {
                            myCompass.active=false
                        }
                    }
                }
            }
        }
    }

    //-------------------------------------------------------------------------
    Component {
        id: calculateButtonComponent

        ImageButton {
            source: "images/refresh_update.png"

            onClicked: {
                changeReason = 0;
                formData.triggerCalculate(bindElement);
            }
        }
    }

    Loader {
        id: calculateButtonLoader

        Layout.preferredWidth: textField.height
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: calculateButtonComponent
        active: false
        visible: showCalculate && active
    }

    //--------------------------------------------------------------------------

    Component {
        id: barcodeButtonComponent

        ImageButton {
            source: "images/barcode-scan.png"

            onClicked: {
                scanBarcode();
            }
        }
    }

    Loader {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: barcodeButtonSize
        Layout.preferredHeight: Layout.preferredWidth

        sourceComponent: barcodeButtonComponent
        active: isBarcode && QtMultimedia.availableCameras.length > 0
        visible: active
    }

    Component {
        id: scanBarcodePage

        XFormBarcodeScan {
            onCodeScanned: {
                setValue(code, 1);
            }
        }
    }

    function scanBarcode() {
        if (QtMultimedia.availableCameras.length <= 0) {
            console.log("No available cameras to scan barcode");
            return;
        }

        Qt.inputMethod.hide();
        xform.popoverStackView.push({
                                        item: scanBarcodePage,
                                        properties: {
                                            formElement: formElement,
                                        }
                                    });
    }

    //--------------------------------------------------------------------------

    Component {
        id: numbersKeypad

        Loader {
            property bool showKeypad: true

            width: parent.width
            height: visible ? (textField.height + AppFramework.displayScaleFactor * 5) * 4 * 1.2  : 0 //150 * AppFramework.displayScaleFactor * xform.style.scale : 0
            active: textField.activeFocus && showKeypad
            visible: active


            onActiveChanged: {
                if (active) {
                    Qt.inputMethod.hide();
                }
            }

            onLoaded: {
                xform.ensureItemVisible(inputLayout.parent.parent);
            }

            sourceComponent: Item {
                MouseArea {
                    anchors.fill: parent

                    enabled: false

                    onClicked: {
                        keypadLoader.showKeypad = false;
                    }
                }

                RowLayout {
                    anchors.fill: parent

                    XFormNumericKeypad {
                        Layout.fillWidth: true
                        Layout.maximumWidth: textField.height * spinnerScale * 5
                        Layout.alignment: Qt.AlignHCenter

                        property bool decimalInput: !(binding.type === binding.kTypeInt)

                        showPoint: decimalInput
                        locale: numberLocale

                        Component.onCompleted: {
                            if (textField.inputMask > "") {
                                showSign = false;
                                showPoint = false;
                            }
                        }

                        onKeyPressed: {
                            var textValue = currentValue;
                            var updateTextField = true;

                            if (textField.inputMask > "") {
                                textValue = textValue.replace(/[^\d]/g, '').trim();
                            }

                            switch (key) {
                            case Qt.Key_plusminus:
                                if (textValue.substring(0, 1) === "-") {
                                    textValue = textValue.substring(1);
                                } else {
                                    textValue = "-" + textValue;
                                }
                                break;

                            case Qt.Key_Enter:
                                updateTextField = false;
                                keypadLoader.showKeypad = false;
                                break;

                            case Qt.Key_Delete:
                                if (textField.length > 0) {
                                    textValue = textValue.slice(0, -1);
                                }
                                break;

                            case Qt.Key_Return:
                                updateTextField = false;
                                textField.editingFinished();
                                break;

                            case Qt.Key_Period:
                                if (textValue.indexOf(".") < 0) {
                                    textValue += ".";
                                }
                                break;

                            default:
                                textValue += text;
                                break;
                            }

                            if (updateTextField) {
                                currentValue = textValue;
                                if (textField.inputMask > "") {
                                    textField.cursorPosition = currentValue.trim().length;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Component {
        id: calculatorKeypad

        Loader {
            property bool showKeypad: true

            width: parent.width
            height: visible ? (textField.height + AppFramework.displayScaleFactor * 5) * 5 * 1.4 : 0
            active: textField.activeFocus && showKeypad
            visible: active


            onActiveChanged: {
                if (active) {
                    Qt.inputMethod.hide();
                }
            }

            onLoaded: {
                xform.ensureItemVisible(inputLayout.parent.parent);
            }

            sourceComponent: Item {
                RowLayout {
                    anchors.fill: parent

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: textField.height * spinnerScale * 6
                        Layout.alignment: Qt.AlignHCenter

                        RowLayout {
                            Layout.fillWidth: true

                            visible: isFinite(calculator.alu.memory) || calculator.alu.currentExpression > ""

                            Text {
                                visible: isFinite(calculator.alu.memory)
                                color: xform.style.hintColor
                                font.pointSize: 10
                                text: "M %1".arg(calculator.alu.memory)
                            }

                            Text {
                                Layout.fillWidth: true

                                color: xform.style.hintColor
                                font.pointSize: 10
                                text: calculator.alu.currentExpression
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                            }
                        }

                        Calculator {
                            id: calculator

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            display.visible: false
                            color: "transparent"
                            locale: numberLocale

                            alu.onInputChanged: {
                                currentValue = alu.input;
                                if (textField.inputMask > "") {
                                    textField.cursorPosition = currentValue.trim().length;
                                }
                            }

                            //                        keypad {
                            //                            equalsKey {
                            //                                operation: alu.kOperationEnter
                            //                                color: "#007aff"
                            //                            }
                            //                        }
                        }
                    }
                }

                Connections {
                    target: textField

                    onEditingFinished: {
                        calculator.alu.setInput(currentValue);
                    }
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    function validateInput() {
        if (!relevant) {
            console.log(logCategory, arguments.callee.name, "Not relevant:", JSON.stringify(bindElement));
            return;
        }

        var isEmpty = currentValue == emptyText;

        if (!isEmpty && constraint) {
            var error = constraint.validate();
            if (error) {
                return error;
            }
        }

        if (debug) {
            console.log(logCategory, arguments.callee.name,
                        "nodeset:", binding.nodeset,
                        "isEmpty:", isEmpty,
                        "currentValue:", JSON.stringify(currentValue),
                        "emptyText:", JSON.stringify(emptyText),
                        "acceptableInput:", textField.acceptableInput,
                        "inputMask:", JSON.stringify(textField.inputMask),
                        "relevant:", relevant,
                        "isRequired:", binding.isRequired);
        }

        var nodeset = binding.nodeset;
        var required = binding.isRequired;

        var field = schema.fieldNodes[nodeset];
        var controlNode = controlNodes[nodeset];

        var label = binding.nodeset;
        if (controlGroup && controlGroup.labelControl) {
            label = controlGroup.labelControl.labelText;
        } else if (field) {
            label = field.label;
        }

        var message;

        if (!message && !isEmpty && !textField.acceptableInput) {
            if (textField.validator && textField.validator.invalidMessage) {
                message = textField.validator.invalidMessage;
            } else {
                message = qsTr("<b>%1</b> input is invalid").arg(label);
            }
        }

        if (!message && required && isEmpty) {
            message = field.requiredMsg > "" ? textLookup(field.requiredMsg) : qsTr("<b>%1</b> is required.").arg(label);
        }

        if (!message) {
            valid = true;
            errorMessage = "";
            return;
        }

        error = {
            "binding": bindElement,
            "message": message,
            "expression": textField.inputMask,
            "activeExpression": currentValue,
            "nodeset": nodeset,
            "field": field,
            "controlNode": controlNode
        };

        valid = false;
        errorMessage = error.message;

        if (debug) {
            console.log(logCategory, arguments.callee.name, "validation error:", error.message);
        }

        return error;
    }

    //--------------------------------------------------------------------------

    function setValue(value, reason) {
        if (debug) {
            console.log(logCategory, arguments.callee.name, "value:", JSON.stringify(value), "typeof:", typeof value, "valueType:", valueType, "reason:", reason, "numberLocale:", numberLocale.name);
        }

        if (typeof value !== valueType && typeof value === "string") {
            value = textToValue(value, value);

            if (debug) {
                console.log(arguments.callee.name, "textToValue value:", JSON.stringify(value));
            }
        }

        var textValue = valueToText(value);

        if (debug) {
            console.log(arguments.callee.name, "valueToText value:", JSON.stringify(value), "textValue:", textValue);
        }

        if (reason) {
            if (reason === 1 && changeReason === 3 && isEqual(textValue, currentValue)) {
                if (debug) {
                    console.log("input setValue == calculated:", JSON.stringify(value));
                }
            } else {
                changeReason = reason;
            }
        } else {
            changeReason = 2;
        }

        currentValue = textValue;
        if (textValue === "") {
            textField.cursorPosition = 0;
        }

        formData.setValue(bindElement, XFormJS.toBindingType(value, bindElement));
    }

    //--------------------------------------------------------------------------

    function valueToText(value) {
        if (XFormJS.isEmpty(value)) {
            return "";
        }

        if (typeof value === "string") {
            return value;
        }

        var text;

        switch (typeof value) {
        case "number":
            switch (binding.type) {
            case binding.kTypeInt:
                text = value.toLocaleString(numberLocale, "", 0);
                break;

            case binding.kTypeDecimal:
                text = XFormJS.numberToLocaleString(numberLocale, value);
                break;

            default:
                text = value.toString();
                break;
            }
            break;

        default:
            text = value.toString();
            break;
        }

        return text;
    }

    //--------------------------------------------------------------------------

    function textToValue(text, invalidValue) {
        var value;

        switch (binding.type) {
        case binding.kTypeInt:
            try {
                value = Number.fromLocaleString(numberLocale, text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            } catch (e) {
                value = parseInt(text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            }
            break;

        case binding.kTypeDecimal:
            try {
                value = Number.fromLocaleString(numberLocale, text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            } catch (e) {
                value = parseFloat(text);
                if (!isFinite(value)) {
                    value = invalidValue;
                }
            }
            break;

        case binding.kTypeDate:
        case binding.kTypeDateTime:
            break;

        default:
            break;
        }

        if (update)

            return value;
    }

    //--------------------------------------------------------------------------

    function typedValue(value) {
        if (typeof value === valueType) {
            return value;
        }

        var tValue = value;

        switch (valueType) {
        case "number":
            tValue = textToValue(value);
            break;

        case "string":
            tValue = valueToText(value);
            break;
        }

        return tValue;
    }

    //--------------------------------------------------------------------------

    function isEqual(value1, value2) {
        return typedValue(value1) === typedValue(value2);
    }

    //--------------------------------------------------------------------------
}
