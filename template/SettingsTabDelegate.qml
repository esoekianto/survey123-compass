import QtQuick 2.9
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

import ArcGIS.AppFramework 1.0

import "../Controls"

Rectangle {
    property var listTabView

    property color iconColor: app.textColor
    property color textColor: app.textColor
    property color hoverBackgroundColor: "#e1f0fb"
    property string fontFamily: app.fontFamily
    property url nextImageSource: "images/next.png"

    width: ListView.view.width
    height: visible ? rowLayout.height + rowLayout.anchors.margins * 2 : 0

    visible: modelData.enabled
    color: mouseArea.containsMouse ? hoverBackgroundColor : "transparent"

    RowLayout {
        id: rowLayout

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 10 * AppFramework.displayScaleFactor
        }

        spacing: 10 * AppFramework.displayScaleFactor

        StyledImage {
            id: iconImage

            Layout.preferredWidth: 45 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            source: modelData.icon
            color: iconColor
        }

        ColumnLayout {
            Layout.fillWidth: true

            spacing: 3 * AppFramework.displayScaleFactor

            Text {
                Layout.fillWidth: true

                text: modelData.title
                color: textColor

                font {
                    pointSize: 16
                    family: fontFamily
                    bold: true
                }

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Text {
                Layout.fillWidth: true

                text: modelData.description
                color: textColor
                visible: text > ""

                font {
                    pointSize: 12
                    family: fontFamily
                }

                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }
        }

        StyledImage {
            Layout.preferredWidth: 25 * AppFramework.displayScaleFactor
            Layout.preferredHeight: Layout.preferredWidth

            source: nextImageSource
            color: iconColor
            visible: source > ""
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            listTabView.selected(modelData);
        }
    }
}

