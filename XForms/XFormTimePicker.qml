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

Item {
    id: timePicker

    property date selectedDate

    property bool isValid: false
    property bool initializing: true

    property real maxColumnWidth: 0
    property real minimumColumnWidth: (44 * AppFramework.displayScaleFactor) * app.textScaleFactor

    property var appearance: null

    property XFormStyle style: null

    property int arrowInset: 3 * AppFramework.displayScaleFactor
    property int arrowWidth: 20 * AppFramework.displayScaleFactor
    property int arrowHeight: 10 * AppFramework.displayScaleFactor
    property bool useArrow: false
    property int leftRightInset: 0

    property int maximumPressAndHoldUpdateInterval: 200
    property int minimumPressAndHoldHourUpdateInterval: 100
    property int minimumPressAndHoldMinuteUpdateInterval: 70

    property bool is12hourAppearance: (
        function () {
            // -----------------------------------------------------------------
            if (appearance !== null && appearance !== undefined) {
                if (appearance === "12hour" || appearance === "hour12") {
                    return true;
                }
                if (appearance === "24hour" || appearance === "hour24") {
                    return false;
                }
            }

            var localeTime = new Date().toLocaleTimeString(xform.locale);
            var localTimeRegEx = new RegExp('(%1)|(%2)'.arg(Qt.locale().amText).arg(Qt.locale().pmText), 'i')
            if (localeTime.search(localTimeRegEx) > -1) {
                return true;
            }
            else {
                return false;
            }
          // -----------------------------------------------------------------
          }()
        )

    property bool am: true
    property bool pm: !am

    property bool modified: false
    property bool userInput: false

    property bool debug: false

    //--------------------------------------------------------------------------

    signal updateSelectedDate()
    signal editingFinished()

    //--------------------------------------------------------------------------

    onSelectedDateChanged: {
        isValid = true;
        updateTimeTextFields();
        modified = true;
    }

    onVisibleChanged: {
        if (visible) {
            modified = false;
            userInput = true;
            if (!isValid) {
                selectedDate = new Date();
            }
        }
        else {
            if (isValid) {
                updateSelectedDate();
            }

            if (userInput && modified) {
                editingFinished();
            }
        }
    }

   onUpdateSelectedDate: {
       updateTime();
   }

    //--------------------------------------------------------------------------

    MouseArea {
        anchors.fill: parent
        enabled: timePicker.visible
        onClicked: {
           if (timePicker.visible) {
               timePicker.visible = false;
           }
        }
    }

   //--------------------------------------------------------------------------

   Rectangle {
       width: timeControls.childrenRect.width + timeControls.anchors.margins + timeControls.spacing + border.width
       height: parent.height
       color: "white"
       radius: 3 * AppFramework.displayScaleFactor
       border {
           width: 1 * AppFramework.displayScaleFactor
           color: style.titleBackgroundColor
       }
       anchors {
           right: xform.languageDirection === Qt.LeftToRight ? parent.right : undefined
           left: xform.languageDirection === Qt.RightToLeft ? parent.left : undefined
       }

       RowLayout {
           id: timeControls
           anchors.fill: parent
           spacing: 5 * AppFramework.displayScaleFactor
           anchors.margins: 6 * AppFramework.displayScaleFactor

           // HOURS ////////////////////////////////////////////////////////////

           ColumnLayout {
               id: hoursColumn
               Layout.fillHeight: true
               Layout.fillWidth: true
               Layout.minimumWidth: minimumColumnWidth
               Layout.maximumWidth: minimumColumnWidth
               spacing: 3 * AppFramework.displayScaleFactor

               // Hour increment -----------------------------------------------

               Rectangle {
                   id: hourIncrement
                   Layout.preferredHeight: parent.height * .3
                   Layout.fillWidth: true

                   Image {
                       source: "images/arrow-up.png"
                       height: (parent.height * .3) * app.textScaleFactor
                       fillMode: Image.PreserveAspectFit
                       anchors.centerIn: parent
                   }

                   MouseArea {
                       anchors.fill: parent
                       pressAndHoldInterval: 500
                       onClicked: {
                           hourIncrement.increment();
                       }
                       onPressAndHold: {
                           hourIncrement.increment();
                           hourIncrementTimer.start();
                       }
                       onReleased: {
                            if (hourIncrementTimer.running) {
                                hourIncrementTimer.stop();
                                hourIncrementTimer.interval = maximumPressAndHoldUpdateInterval;
                            }
                       }
                   }

                   Timer {
                       id: hourIncrementTimer
                       interval: maximumPressAndHoldUpdateInterval
                       running: false
                       repeat: true
                       onTriggered: {
                           hourIncrement.increment();
                           if (interval > minimumPressAndHoldUpdateInterval) {
                               interval -= 10;
                           }
                       }
                   }

                   function increment(){
                        controlHours.setByButton = true;
                        if (controlHours.text > "") {
                            updateHours(1);
                        }
                    }
                }

                // Hour Text Entry ---------------------------------------------

                TextField {
                   id: controlHours

                   property bool setByButton: false

                   Layout.fillHeight: true
                   Layout.fillWidth: true
                   padding: 0
                   verticalAlignment: Text.AlignVCenter
                   horizontalAlignment: Text.AlignHCenter
                   validator: hourRegex
                   inputMethodHints: Qt.ImhDigitsOnly
                   font {
                       bold: xform.style.inputBold
                       pointSize: xform.style.inputPointSize
                       family: xform.style.inputFontFamily
                   }

                   onTextChanged: {
                       setByButton = false;
                   }

                   onFocusChanged: {
                       if (focus) {
                           selectAll();
                       }
                   }
                }

                // Hour Decrement ----------------------------------------------

                Rectangle {
                    id: hourDecrement
                    Layout.preferredHeight: parent.height * .3
                    Layout.fillWidth: true

                    Image {
                        source: "images/arrow-down.png"
                        height: (parent.height * .3) * app.textScaleFactor
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        pressAndHoldInterval: 500
                        onClicked: {
                            hourDecrement.decrement();
                        }
                        onPressAndHold: {
                            hourDecrement.decrement();
                            hourDecrementTimer.start();
                        }
                        onReleased: {
                             if (hourDecrementTimer.running) {
                                 hourDecrementTimer.stop();
                                 hourDecrementTimer.interval = maximumPressAndHoldUpdateInterval;
                             }
                        }
                    }

                    Timer {
                        id: hourDecrementTimer
                        interval: maximumPressAndHoldUpdateInterval
                        running: false
                        repeat: true
                        onTriggered: {
                            hourDecrement.decrement();
                            if (interval > minimumPressAndHoldUpdateInterval) {
                                interval -= 10;
                            }
                        }
                    }
                    function decrement(){
                        controlHours.setByButton = true;
                        if (controlHours.text > "") {
                            updateHours(-1);
                        }
                    }
                }
            }

           // SEPARATOR ////////////////////////////////////////////////////////

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                Text {
                    anchors.centerIn: parent
                    text: ":"
                }
            }

            // MINUTES /////////////////////////////////////////////////////////

            ColumnLayout {
               id: minutesColumn
               Layout.fillHeight: true
               Layout.fillWidth: true
               Layout.minimumWidth: minimumColumnWidth
               Layout.maximumWidth: minimumColumnWidth
               spacing: 3 * AppFramework.displayScaleFactor

               // Minute Increment ---------------------------------------------

               Rectangle {
                   id: minuteIncrement
                   Layout.preferredHeight: parent.height * .3
                   Layout.fillWidth: true

                   Image {
                       source: "images/arrow-up.png"
                       height: (parent.height * .3) * app.textScaleFactor
                       fillMode: Image.PreserveAspectFit
                       anchors.centerIn: parent
                   }

                   MouseArea {
                       anchors.fill: parent
                       pressAndHoldInterval: 500
                       onClicked: {
                           minuteIncrement.increment();
                       }
                       onPressAndHold: {
                           minuteIncrement.increment();
                           minuteIncrementTimer.start();
                       }
                       onReleased: {
                            if (minuteIncrementTimer.running) {
                                minuteIncrementTimer.stop();
                                minuteIncrementTimer.interval = maximumPressAndHoldUpdateInterval;
                            }
                       }
                   }

                   Timer {
                       id: minuteIncrementTimer
                       interval: maximumPressAndHoldUpdateInterval
                       running: false
                       repeat: true
                       onTriggered: {
                           minuteIncrement.increment();
                           if (interval > minimumPressAndHoldMinuteUpdateInterval) {
                               interval -= 10;
                           }
                       }
                   }

                   function increment(){
                        controlMinutes.setByButton = true;
                        if (controlMinutes.text > "") {
                            updateMinutes(1);
                        }
                    }
                }

                // Minute Time Entry -------------------------------------------

                TextField {
                    id: controlMinutes

                    property bool setByButton: false

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    validator: minuteRegex
                    inputMethodHints: Qt.ImhDigitsOnly
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter

                    font {
                        bold: xform.style.inputBold
                        pointSize: xform.style.inputPointSize
                        family: xform.style.inputFontFamily
                    }

                    onTextChanged: {
                        setByButton = false;
                    }

                    onFocusChanged: {
                        if (focus) {
                            selectAll();
                        }
                    }
                }

                // Minute Decrement --------------------------------------------

                Rectangle {
                    id: minuteDecrement
                    Layout.preferredHeight: parent.height * .3
                    Layout.fillWidth: true

                    Image {
                        source: "images/arrow-down.png"
                        height: (parent.height * .3) * app.textScaleFactor
                        fillMode: Image.PreserveAspectFit
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        pressAndHoldInterval: 500
                        onClicked: {
                            minuteDecrement.decrement();
                        }
                        onPressAndHold: {
                            minuteDecrement.decrement();
                            minuteDecrementTimer.start();
                        }
                        onReleased: {
                            if (minuteDecrementTimer.running) {
                                minuteDecrementTimer.stop();
                                minuteDecrementTimer.interval = maximumPressAndHoldUpdateInterval;
                            }
                        }
                    }

                    Timer {
                        id: minuteDecrementTimer
                        interval: maximumPressAndHoldUpdateInterval
                        running: false
                        repeat: true
                        onTriggered: {
                            minuteDecrement.decrement();
                            if (interval > minimumPressAndHoldMinuteUpdateInterval) {
                                interval -= 10;
                            }
                        }
                    }
                    function decrement(){
                        controlMinutes.setByButton = true;
                        if (controlMinutes.text > "") {
                            updateMinutes(-1);
                        }
                    }
                }
            }

            // MERIDIEM ////////////////////////////////////////////////////////

            Rectangle {
                Layout.preferredWidth: 1 * AppFramework.displayScaleFactor
                Layout.fillHeight: true
                visible: is12hourAppearance
                color: "#ddd"
            }

            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
                Layout.minimumWidth: minimumColumnWidth
                Layout.maximumWidth: minimumColumnWidth
                visible: is12hourAppearance
                ColumnLayout {
                    id: meridiemColumn
                    anchors.fill: parent
                    spacing: 3 * AppFramework.displayScaleFactor

                    Button {
                        id: amButton
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        enabled: !am
                        background: Rectangle {
                            radius: 3 * AppFramework.displayScaleFactor
                        }
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            font {
                                bold: am
                                pointSize: am ? xform.style.inputPointSize * 1.2 : xform.style.inputPointSize
                                family: xform.style.inputFontFamily
                            }
                            text: Qt.locale().amText
                        }

                        onClicked: {
                            am = true;
                            updateTime();
                        }
                    }
                    Rectangle {
                        id: meridiemColumnSeparator
                        Layout.preferredHeight: 1 * AppFramework.displayScaleFactor
                        Layout.fillWidth: true
                        color: "#ddd"
                    }
                    Button {
                        id: pmButton
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        enabled: am
                        background: Rectangle {
                            radius: 3 * AppFramework.displayScaleFactor
                        }
                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            font {
                                bold: pm
                                pointSize: pm ? xform.style.inputPointSize * 1.2 : xform.style.inputPointSize
                                family: xform.style.inputFontFamily
                            }
                            text: Qt.locale().pmText
                        }

                        onClicked: {
                            am = false;
                            updateTime();
                        }
                    }
                }
            }
        }
    }

    // ARROW ///////////////////////////////////////////////////////////////////

    Canvas {
       width: arrowWidth;
       height: arrowHeight;
       x: timePicker.width - arrowWidth - arrowInset - timePicker.leftRightInset
       y: (0 - height - timePicker.anchors.margins) + 1
       z: timePicker.z - 30;
       visible: useArrow
       onPaint: {
           if (available) {
               var ctx = getContext("2d");
               ctx.fillStyle = timePicker.style.titleBackgroundColor;
               ctx.beginPath();
               ctx.moveTo(width/2, 0);

               ctx.lineTo(width, height);
               ctx.lineTo(0, height);
               ctx.lineTo(width/2,0);
               ctx.closePath();
               ctx.fill();
            }
        }
    }

   //--------------------------------------------------------------------------

    RegExpValidator {
        id: hourRegex
        regExp: is12hourAppearance ? /^[0-9]|0[0-9]|1[0-2]/ : /^[0-9]|0[0-9]|1[0-9]|2[0-3]/
    }

    //--------------------------------------------------------------------------

    RegExpValidator {
        id: minuteRegex
        regExp: /^[0-5][0-9]$/
    }

    //--------------------------------------------------------------------------

    function updateHours(amount) {

        if (amount === undefined) {
            return;
        }

        var increment = amount > 0;
        var decrement = amount < 0;

        var hoursAsInt = controlHours.text > "" ? getStringTimeAsInt(controlHours.text) : 0;

        var newHoursAsInt;

        if (!is12hourAppearance) {
            if (increment) {
                newHoursAsInt = hoursAsInt < 23 ? hoursAsInt + amount : 0;
            }
            if (decrement) {
                newHoursAsInt = hoursAsInt > 0 ? hoursAsInt + amount : 23;
            }
        }

        if (is12hourAppearance) {
            if (increment) {
                newHoursAsInt = hoursAsInt < 12 ? hoursAsInt + amount : 1;
            }
            if (decrement) {
                newHoursAsInt = hoursAsInt > 1 ? hoursAsInt + amount : 12;
            }
        }

        var newTime = {
            "hours": newHoursAsInt,
            "minutes": controlMinutes.text > "" ? getStringTimeAsInt(controlMinutes.text) : 0
        }

        updateTime(newTime);

        var hoursAsString = getIntTimeAsString(newHoursAsInt);
        controlHours.text = hoursAsString;

    }

    //--------------------------------------------------------------------------

    function updateMinutes(amount) {

        if (amount === undefined) {
            return;
        }

        var increment = amount > 0;
        var decrement = amount < 0;

        var minutesAsInt = controlMinutes.text > "" ? getStringTimeAsInt(controlMinutes.text) : 0;

        var newMinutesAsInt;

            if (increment) {
                newMinutesAsInt = minutesAsInt < 59 ? minutesAsInt + amount : 0;
            }
            if (decrement) {
                newMinutesAsInt = minutesAsInt === 0 ? 59 : minutesAsInt + amount;
            }

        var newTime = {
                "hours": controlHours.text > "" ? getStringTimeAsInt(controlHours.text) : 0,
                "minutes": newMinutesAsInt
            }

        updateTime(newTime);

        var minutesAsString = getIntTimeAsString(newMinutesAsInt);
        controlMinutes.text = minutesAsString;
    }

    //--------------------------------------------------------------------------

    function clear() {
        selectedDate.setTime(NaN);
        isValid = false;
    }

    //--------------------------------------------------------------------------

    function updateTime(hoursMinutes) {

        if (hoursMinutes === undefined) {
            hoursMinutes = {
                "hours": (controlHours.text > "" ? getStringTimeAsInt(controlHours.text) : 12),
                "minutes": (controlMinutes.text > "" ? getStringTimeAsInt(controlMinutes.text) : 0)
            }
        }

        if (debug) {
            console.log("---> hoursMinutes: ", JSON.stringify(hoursMinutes));
        }

        var time = new Date();

        if (isValid) {
            time.setTime(selectedDate.getTime());
        }

        if (hoursMinutes.hasOwnProperty("hours")) {
            var hours = hoursMinutes.hours;

            if (is12hourAppearance){
                if (am && hours === 12) {
                    hours = 0;
                }

                if (pm && hours < 12) {
                    hours += 12;
                }
            }

            time.setHours(hours);
        }

        if (hoursMinutes.hasOwnProperty("minutes")) {
            time.setMinutes(hoursMinutes.minutes);
        }

        time.setSeconds(0);
        time.setMilliseconds(0);

        if (selectedDate.getTime() != time.getTime()) {
            isValid = true;
            selectedDate = time;
            if (debug) {
                console.log("--------->>>: ", selectedDate);
            }
        }
    }

    //--------------------------------------------------------------------------

    function updateTimeTextFields() {

        var time = new Date();

        if (isValid) {
            time.setTime(selectedDate.getTime());
        }

        var parsedTime = get24HourTime(time);

        if (initializing) {
            am = (parsedTime.hours < 12) ? true : false;
            initializing = false;
        }

        controlMinutes.text = parsedTime.minutes.toString();

        controlHours.text = !is12hourAppearance ? getIntTimeAsString(parsedTime.hours) : getIntTimeAsString(parsedTime.civilianHours);
    }

    //--------------------------------------------------------------------------

    function getStringTimeAsInt(stringTime) {
        if (debug) {
            console.log("stringTime: ", stringTime);
        }

//        if (stringTime === "") {
//            stringTime = "0";
//        }

        var currentTimeComponent = stringTime;

        if (currentTimeComponent.search(/^0[0-9]/) > -1) {
            var timeComponentWithoutLeadingZero = currentTimeComponent.charAt(1);
            currentTimeComponent = timeComponentWithoutLeadingZero;
        }

        var parsedTime = parseInt(currentTimeComponent, 10);

        return parsedTime;
    }

    //--------------------------------------------------------------------------

    function getIntTimeAsString(intTime) {
        var stringTime = intTime.toString();
        if (intTime < 10) {
            stringTime = "0" + stringTime;
        }

        if (debug) {
            console.log("intTimetolocale: ", intTime.toLocaleString());
        }

        return stringTime;
    }

    //--------------------------------------------------------------------------

    function get24HourTime(datestamp) {

        var dateStampToFormattedTimeString = Qt.formatTime(datestamp, Qt.ISODate);
        var timeValues = dateStampToFormattedTimeString.split(':');
        var militaryHours = parseInt(timeValues[0], 10);
        var civilianHours = militaryHours;

        if (militaryHours === 0 /*|| militaryHours === 12*/) {
            civilianHours = 12;
        }

        if (militaryHours > 12) {
            civilianHours = militaryHours - 12;
        }

        var time = {
            "hours": militaryHours,
            "civilianHours": civilianHours,
            "minutes": timeValues[1],
        }

        if (debug) {
            console.log(JSON.stringify(time));
        }

        return time;
    }

    //--------------------------------------------------------------------------
}
