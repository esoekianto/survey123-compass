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

RowLayout {
    id: labelControl

    property XFormData formData

    property bool required: false
    property var label
    property string labelText
    property string ttsText : labelText

    readonly property var textValue: translationTextValue(label, language)
    readonly property string imageSource: mediaValue(label, "image", language)
    readonly property string audioSource: mediaValue(label, "audio", language)
    
    //--------------------------------------------------------------------------

    anchors {
        left: parent.left
        right: parent.right
    }

    layoutDirection: xform.languageDirection

    //--------------------------------------------------------------------------

    onTextValueChanged: {
        labelText = formData.createTextExpression(textValue);
    }

    //--------------------------------------------------------------------------

    Column {
        Layout.fillWidth: true
        Layout.fillHeight: true

        spacing: 5 * AppFramework.displayScaleFactor

        Loader {
            sourceComponent: labelTextComponent
            width: parent.width
        }

        Loader {
            width: parent.width
            sourceComponent: imageComponent
            active: imageSource > ""
        }
    }
    
    //--------------------------------------------------------------------------

    Component {
        id: labelTextComponent

        Text {
            text: XFormJS.encodeHTMLEntities(labelText.trim()) + (required ? ' <font color="%1">*</font>'.arg(xform.style.requiredColor) : "")
            color: xform.style.labelColor
            font {
                pointSize: xform.style.labelPointSize
                bold: xform.style.labelBold
                family: xform.style.labelFontFamily
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            visible: text > ""
            textFormat: Text.RichText

            onLinkActivated: {
                Qt.openUrlExternally(link);
            }
        }
    }

    Component {
        id: imageComponent

        Image {
            source: imageSource
            fillMode: Image.PreserveAspectFit

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    xform.popoverStackView.push({
                                                    item: valuesPreview,
                                                    properties: {
                                                        values: labelControl.label
                                                    }
                                                });
                }
            }
        }
    }

    //--------------------------------------------------------------------------

    Loader {
        sourceComponent: component_ColumnLayout
        active: audioSource > ""
    }

    Component {
        id: component_ColumnLayout
        ColumnLayout {
            XFormAudioButton {
                Layout.preferredWidth: xform.style.playButtonSize
                Layout.preferredHeight: Layout.preferredWidth

                audio {
                    source: audioSource
                }

                ttsText: labelControl.ttsText
            }
        }
    }

    //--------------------------------------------------------------------------
}
