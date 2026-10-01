// monOS SDDM theme: round user picture. Falls back to the user's initial on
// an accent circle when the user has no picture (SDDM's generic default
// face, an unreadable ~/.face.icon) or when the picture fails to load.

import QtQuick
import QtQuick.Effects

Item {
    id: avatar

    property url source
    property string label
    property bool highlighted: false
    // The current user's initial sits on the accent color, the others on
    // a neutral surface.
    property bool active: true
    property color accent: "#0C6BFA"
    property color accentForeground: "#FCFCFC"
    property color inactiveColor: "#232833"
    property color inactiveForeground: "#A9B1C1"
    property color ring: "#2E3440"
    property string fontFamily

    // Rounded masking needs a GPU scene graph; the software renderer shows
    // the square picture instead.
    readonly property bool canMask: GraphicsInfo.api !== GraphicsInfo.Software
    readonly property bool generic: {
        const s = source.toString();
        return s === "" || s.endsWith("/faces/.face.icon");
    }
    readonly property bool showPicture: !generic && picture.status === Image.Ready

    implicitWidth: 72
    implicitHeight: 72

    Rectangle {
        id: initialCircle
        anchors.fill: parent
        radius: width / 2
        color: avatar.active ? avatar.accent : avatar.inactiveColor
        visible: !avatar.showPicture

        Text {
            anchors.centerIn: parent
            text: avatar.label.length > 0 ? avatar.label.charAt(0).toUpperCase() : "?"
            color: avatar.active ? avatar.accentForeground : avatar.inactiveForeground
            font.family: avatar.fontFamily
            font.pixelSize: parent.height * 0.42
            font.weight: Font.DemiBold
        }
    }

    Image {
        id: picture
        anchors.fill: parent
        source: avatar.generic ? "" : avatar.source
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        visible: avatar.showPicture && !avatar.canMask
    }

    MultiEffect {
        anchors.fill: picture
        source: picture
        visible: avatar.showPicture && avatar.canMask
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Item {
        id: mask
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        visible: false

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "black"
        }
    }

    // Selection ring.
    Rectangle {
        anchors.fill: parent
        anchors.margins: -4
        radius: width / 2
        color: "transparent"
        border.width: avatar.highlighted ? 2 : 1
        border.color: avatar.highlighted ? avatar.accent : avatar.ring
    }
}
