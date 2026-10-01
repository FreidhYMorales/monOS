// monOS SDDM theme: flat button with a Nerd Font glyph and an optional
// label. Keyboard: Tab focuses it (accent outline), Space/Enter activate it.

import QtQuick
import QtQuick.Controls.Basic

Button {
    id: control

    property string glyph
    property string label
    property string fontFamily
    property color foreground: "#E6E9EF"
    property color hoverBackground: "#232833"
    property color focusColor: "#0C6BFA"
    property color filledColor: "transparent"
    property int glyphSize: 18
    property real radius: 8

    focusPolicy: Qt.StrongFocus
    hoverEnabled: true
    padding: 8
    leftPadding: label.length > 0 ? 12 : 8
    rightPadding: label.length > 0 ? 14 : 8

    Accessible.name: label.length > 0 ? label : ToolTip.text

    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()

    contentItem: Row {
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: control.glyph
            color: control.foreground
            font.family: control.fontFamily
            font.pixelSize: control.glyphSize
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: control.label.length > 0
            text: control.label
            color: control.foreground
            font.family: control.fontFamily
            font.pixelSize: 14
        }
    }

    background: Rectangle {
        implicitWidth: 36
        implicitHeight: 36
        radius: control.radius
        color: control.filledColor.a > 0
            ? (control.down ? Qt.darker(control.filledColor, 1.15) : control.hovered ? Qt.lighter(control.filledColor, 1.12) : control.filledColor)
            : (control.down || control.hovered ? control.hoverBackground : "transparent")
        border.width: control.visualFocus ? 2 : 0
        border.color: control.focusColor
    }

    ToolTip.visible: hovered && ToolTip.text.length > 0
    ToolTip.delay: 600
}
