// monOS SDDM greeter theme (SDDM 0.21, Qt 6 greeter: sddm-greeter-qt6).
//
// Only Qt Quick, Qt Quick Controls (Basic style), Qt Quick Effects and SDDM's
// own SddmComponents (for the translated strings) are used: no Plasma or
// Kirigami imports, the greeter runs outside a Plasma session.
// Colors, fonts and the background come from theme.conf, which
// branding/tools/gen-themes.py renders from the monOS palette.
//
// SDDM context properties: sddm (login, power actions, hostName, signals
// loginFailed / informationMessage), userModel, sessionModel, keyboard
// (layouts, currentLayout, capsLock), config (theme.conf), primaryScreen.

import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import SddmComponents 2.0 as Sddm
import "components"

Rectangle {
    id: root

    width: 1920
    height: 1080

    // --- theme.conf ---------------------------------------------------------
    function cfg(key, fallback) {
        const value = config.stringValue(key);
        return value !== undefined && value !== null && value.length > 0 ? value : fallback;
    }
    function cfgReal(key, fallback) {
        const value = parseFloat(cfg(key, ""));
        return isNaN(value) ? fallback : value;
    }
    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property color colorBackground: cfg("colorBackground", "#0B0D12")
    readonly property color colorSurface: cfg("colorSurface", "#12151C")
    readonly property color colorSurface2: cfg("colorSurface2", "#1A1E27")
    readonly property color colorOverlay: cfg("colorOverlay", "#232833")
    readonly property color colorBorder: cfg("colorBorder", "#2E3440")
    readonly property color colorText: cfg("colorText", "#E6E9EF")
    readonly property color colorTextDim: cfg("colorTextDim", "#A9B1C1")
    readonly property color colorMuted: cfg("colorMuted", "#7D8699")
    readonly property color colorAccent: cfg("colorAccent", "#0C6BFA")
    readonly property color colorOnAccent: cfg("colorOnAccent", "#FCFCFC")
    readonly property color colorAccentText: cfg("colorAccentText", "#3D8BFF")
    readonly property color colorSelection: cfg("colorSelection", "#1F3B6E")
    readonly property color colorError: cfg("colorError", "#F2555A")
    readonly property color colorWarning: cfg("colorWarning", "#F5C451")
    readonly property string fontFamily: cfg("font", "JetBrainsMono Nerd Font Propo")
    readonly property real panelOpacity: cfgReal("panelOpacity", 0.78)
    readonly property real dimOpacity: cfgReal("dim", 0.35)
    readonly property real blurAmount: cfgReal("blur", 0.6)
    readonly property string clockFormat: cfg("clockFormat", "HH:mm")
    readonly property string dateFormat: cfg("dateFormat", "dddd, d MMMM")

    // Nerd Font glyphs (Material Design range of Nerd Fonts 3).
    readonly property string glyphSuspend: "\u{F0904}"
    readonly property string glyphReboot: "\u{F0709}"
    readonly property string glyphShutdown: "\u{F0425}"
    readonly property string glyphEye: "\u{F0208}"
    readonly property string glyphEyeOff: "\u{F0209}"
    readonly property string glyphKeyboard: "\u{F030C}"
    readonly property string glyphSession: "\u{F0379}"
    readonly property string glyphLogin: "\u{F0054}"
    readonly property string glyphCapsLock: "\u{F0632}"
    readonly property string glyphError: "\u{F05D6}"

    // --- state --------------------------------------------------------------
    readonly property bool hasUsers: userModel.count > 0
    readonly property string currentUser: hasUsers
        ? (userList.currentItem ? userList.currentItem.login : "")
        : usernameField.text
    property bool busy: false
    property string message: ""
    property bool messageIsError: false

    color: colorBackground

    Sddm.TextConstants {
        id: tr
    }

    function login() {
        if (busy || currentUser.length === 0)
            return;
        busy = true;
        message = "";
        sddm.login(currentUser, passwordField.text, sessionBox.currentIndex);
    }

    Connections {
        target: sddm

        function onLoginFailed() {
            root.busy = false;
            root.message = tr.loginFailed;
            root.messageIsError = true;
            passwordField.text = "";
            passwordField.forceActiveFocus();
            shake.restart();
        }

        function onInformationMessage(message) {
            root.busy = false;
            root.message = message;
            root.messageIsError = false;
        }
    }

    // --- background ---------------------------------------------------------
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.cfg("background", "")
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: false
        visible: !blurredWallpaper.visible
    }

    // The software renderer has no shader effects: the plain picture shows.
    MultiEffect {
        id: blurredWallpaper
        anchors.fill: wallpaper
        source: wallpaper
        visible: root.blurAmount > 0 && GraphicsInfo.api !== GraphicsInfo.Software
        blurEnabled: true
        blur: root.blurAmount
        blurMax: 48
        autoPaddingEnabled: false
    }

    Rectangle {
        anchors.fill: parent
        color: root.colorBackground
        opacity: root.dimOpacity
    }

    // --- top bar: logo + host name, power actions ---------------------------
    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 28
        spacing: 14

        Image {
            anchors.verticalCenter: parent.verticalCenter
            source: root.cfg("logo", "")
            height: 30
            sourceSize.height: 60
            fillMode: Image.PreserveAspectFit
            visible: status === Image.Ready
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: sddm.hostName
            color: root.colorTextDim
            font.family: root.fontFamily
            font.pixelSize: 15
        }
    }

    // --- center: clock, login card, session/keyboard ------------------------
    Column {
        id: center
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.03
        spacing: 0

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.colorText
            font.family: root.fontFamily
            font.pixelSize: Math.round(Math.min(root.height * 0.1, 108))
            font.weight: Font.Light
            text: Qt.formatTime(timeSource.now, root.clockFormat)
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.colorTextDim
            font.family: root.fontFamily
            font.pixelSize: 20
            text: Qt.locale().toString(timeSource.now, root.dateFormat)
        }

        Item {
            width: 1
            height: Math.round(root.height * 0.045)
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            width: 400
            height: cardContent.implicitHeight + 56
            radius: 16
            color: root.withAlpha(root.colorSurface2, root.panelOpacity)
            border.width: 1
            border.color: root.withAlpha(root.colorBorder, 0.9)

            transform: Translate {
                id: shakeOffset
            }

            SequentialAnimation {
                id: shake
                loops: 2
                NumberAnimation { target: shakeOffset; property: "x"; to: -10; duration: 50 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 10; duration: 80 }
                NumberAnimation { target: shakeOffset; property: "x"; to: 0; duration: 50 }
            }

            Column {
                id: cardContent
                anchors.top: parent.top
                anchors.topMargin: 28
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 56
                spacing: 16

                // Users: Left/Right (or a click) picks one; the current one
                // is shown larger with an accent ring.
                ListView {
                    id: userList
                    visible: root.hasUsers
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(parent.width, contentWidth)
                    height: 120
                    orientation: ListView.Horizontal
                    spacing: 12
                    interactive: contentWidth > width
                    clip: true
                    model: userModel
                    currentIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
                    highlightFollowsCurrentItem: true
                    keyNavigationWraps: true
                    activeFocusOnTab: userModel.count > 1
                    Accessible.role: Accessible.List
                    Accessible.name: tr.userName

                    Keys.onReturnPressed: passwordField.forceActiveFocus()
                    Keys.onEnterPressed: passwordField.forceActiveFocus()

                    delegate: Item {
                        id: userDelegate
                        required property int index
                        required property string name
                        required property string realName
                        required property url icon
                        readonly property string login: name
                        readonly property bool isCurrent: ListView.isCurrentItem

                        width: Math.max(88, userLabel.implicitWidth)
                        height: userList.height

                        Avatar {
                            id: userAvatar
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: userDelegate.isCurrent ? 4 : 16
                            width: userDelegate.isCurrent ? 72 : 52
                            height: width
                            source: userDelegate.icon
                            label: userDelegate.realName.length > 0 ? userDelegate.realName : userDelegate.name
                            highlighted: userDelegate.isCurrent && (userList.activeFocus || userModel.count > 1)
                            active: userDelegate.isCurrent
                            accent: root.colorAccent
                            accentForeground: root.colorOnAccent
                            inactiveColor: root.colorOverlay
                            inactiveForeground: root.colorTextDim
                            ring: root.colorBorder
                            fontFamily: root.fontFamily

                            Behavior on width { NumberAnimation { duration: 120 } }
                        }

                        Text {
                            id: userLabel
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            text: userDelegate.realName.length > 0 ? userDelegate.realName : userDelegate.name
                            color: userDelegate.isCurrent ? root.colorText : root.colorMuted
                            font.family: root.fontFamily
                            font.pixelSize: userDelegate.isCurrent ? 16 : 13
                            font.weight: userDelegate.isCurrent ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 160)
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                userList.currentIndex = userDelegate.index;
                                passwordField.forceActiveFocus();
                            }
                        }
                    }
                }

                // Without a user list (no users above SDDM's minimum UID) the
                // user name is typed.
                TextField {
                    id: usernameField
                    visible: !root.hasUsers
                    width: parent.width
                    height: 44
                    placeholderText: tr.userName
                    placeholderTextColor: root.colorMuted
                    color: root.colorText
                    selectionColor: root.colorSelection
                    selectedTextColor: root.colorText
                    font.family: root.fontFamily
                    font.pixelSize: 15
                    leftPadding: 14
                    background: Rectangle {
                        radius: 10
                        color: root.withAlpha(root.colorBackground, 0.55)
                        border.width: usernameField.activeFocus ? 2 : 1
                        border.color: usernameField.activeFocus ? root.colorAccent : root.colorBorder
                    }
                    KeyNavigation.tab: passwordField
                    onAccepted: passwordField.forceActiveFocus()
                }

                Row {
                    width: parent.width
                    spacing: 10

                    TextField {
                        id: passwordField
                        width: parent.width - loginButton.width - parent.spacing
                        height: 44
                        focus: true
                        enabled: !root.busy
                        echoMode: revealButton.checked ? TextInput.Normal : TextInput.Password
                        passwordCharacter: "•"
                        placeholderText: tr.password
                        placeholderTextColor: root.colorMuted
                        color: root.colorText
                        selectionColor: root.colorSelection
                        selectedTextColor: root.colorText
                        font.family: root.fontFamily
                        font.pixelSize: 15
                        leftPadding: 14
                        rightPadding: revealButton.width + 8
                        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        Accessible.name: tr.password
                        background: Rectangle {
                            radius: 10
                            color: root.withAlpha(root.colorBackground, 0.55)
                            border.width: passwordField.activeFocus ? 2 : 1
                            border.color: root.messageIsError && root.message.length > 0
                                ? root.colorError
                                : passwordField.activeFocus ? root.colorAccent : root.colorBorder
                        }
                        onAccepted: root.login()
                        onTextEdited: if (root.messageIsError) root.message = ""

                        IconButton {
                            id: revealButton
                            anchors.right: parent.right
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            checkable: true
                            glyph: checked ? root.glyphEyeOff : root.glyphEye
                            glyphSize: 18
                            padding: 6
                            fontFamily: root.fontFamily
                            foreground: root.colorTextDim
                            hoverBackground: root.colorOverlay
                            focusColor: root.colorAccent
                            ToolTip.text: checked ? tr.hidePasswordPrompt : tr.showPasswordPrompt
                        }
                    }

                    IconButton {
                        id: loginButton
                        width: 44
                        height: 44
                        radius: 10
                        enabled: !root.busy && root.currentUser.length > 0
                        glyph: root.glyphLogin
                        glyphSize: 20
                        fontFamily: root.fontFamily
                        foreground: root.colorOnAccent
                        filledColor: root.colorAccent
                        focusColor: root.colorText
                        opacity: enabled ? 1 : 0.6
                        ToolTip.text: tr.login
                        onClicked: root.login()
                    }
                }

                // Caps Lock and login messages share one line under the field.
                Item {
                    width: parent.width
                    height: Math.max(capsRow.implicitHeight, messageRow.implicitHeight)
                    visible: capsRow.visible || messageRow.visible

                    Row {
                        id: messageRow
                        visible: root.message.length > 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: root.glyphError
                            visible: root.messageIsError
                            color: root.colorError
                            font.family: root.fontFamily
                            font.pixelSize: 15
                        }
                        Text {
                            text: root.message
                            color: root.messageIsError ? root.colorError : root.colorTextDim
                            font.family: root.fontFamily
                            font.pixelSize: 14
                        }
                    }

                    Row {
                        id: capsRow
                        visible: !messageRow.visible && keyboard.capsLock
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: root.glyphCapsLock
                            color: root.colorWarning
                            font.family: root.fontFamily
                            font.pixelSize: 15
                        }
                        Text {
                            text: tr.capslockWarning
                            color: root.colorWarning
                            font.family: root.fontFamily
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }

        Item {
            width: 1
            height: 16
        }

        // Session and keyboard layout.
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            ComboBox {
                id: sessionBox
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                visible: sessionModel.count > 0
                width: Math.max(200, implicitContentWidth + 64)
                height: 36
                font.family: root.fontFamily
                font.pixelSize: 14
                Accessible.name: tr.session

                Keys.onReturnPressed: popup.open()
                Keys.onEnterPressed: popup.open()

                contentItem: Row {
                    leftPadding: 12
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.glyphSession
                        color: root.colorTextDim
                        font.family: root.fontFamily
                        font.pixelSize: 16
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: sessionBox.displayText
                        color: root.colorText
                        font: sessionBox.font
                    }
                }

                indicator: Text {
                    x: sessionBox.width - width - 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0140}"
                    color: root.colorTextDim
                    font.family: root.fontFamily
                    font.pixelSize: 16
                }

                background: Rectangle {
                    radius: 8
                    color: sessionBox.hovered || sessionBox.popup.visible
                        ? root.withAlpha(root.colorOverlay, 0.9)
                        : root.withAlpha(root.colorSurface2, root.panelOpacity)
                    border.width: sessionBox.visualFocus ? 2 : 1
                    border.color: sessionBox.visualFocus ? root.colorAccent : root.withAlpha(root.colorBorder, 0.9)
                }

                delegate: ItemDelegate {
                    id: sessionDelegate
                    required property int index
                    required property string name
                    width: sessionBox.width
                    height: 34
                    highlighted: sessionBox.highlightedIndex === index
                    contentItem: Text {
                        text: sessionDelegate.name
                        color: sessionDelegate.highlighted ? root.colorOnAccent : root.colorText
                        font: sessionBox.font
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                    background: Rectangle {
                        radius: 6
                        color: sessionDelegate.highlighted ? root.colorAccent : "transparent"
                    }
                }

                popup: Popup {
                    y: sessionBox.height + 4
                    width: sessionBox.width
                    implicitHeight: contentItem.implicitHeight + 8
                    padding: 4

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                        currentIndex: sessionBox.highlightedIndex
                    }

                    background: Rectangle {
                        radius: 8
                        color: root.colorSurface2
                        border.width: 1
                        border.color: root.colorBorder
                    }
                }
            }

            // Click (or Space/Enter) switches to the next layout.
            IconButton {
                id: layoutButton
                readonly property var layouts: keyboard.layouts
                visible: keyboard.enabled && layouts && layouts.length > 0
                height: 36
                glyph: root.glyphKeyboard
                label: visible && keyboard.currentLayout >= 0 && keyboard.currentLayout < layouts.length
                    ? layouts[keyboard.currentLayout].shortName.toUpperCase()
                    : ""
                fontFamily: root.fontFamily
                foreground: root.colorText
                hoverBackground: root.withAlpha(root.colorOverlay, 0.9)
                filledColor: root.withAlpha(root.colorSurface2, root.panelOpacity)
                focusColor: root.colorAccent
                ToolTip.text: visible && keyboard.currentLayout >= 0 && keyboard.currentLayout < layouts.length
                    ? tr.layout + ": " + layouts[keyboard.currentLayout].longName
                    : tr.layout
                onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % layouts.length
            }
        }
    }

    // --- power actions (last in the Tab order) -------------------------------
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 24
        spacing: 6

        IconButton {
            visible: sddm.canSuspend
            glyph: root.glyphSuspend
            label: tr.suspend
            fontFamily: root.fontFamily
            foreground: root.colorText
            hoverBackground: root.withAlpha(root.colorOverlay, 0.85)
            focusColor: root.colorAccent
            onClicked: sddm.suspend()
        }
        IconButton {
            visible: sddm.canReboot
            glyph: root.glyphReboot
            label: tr.reboot
            fontFamily: root.fontFamily
            foreground: root.colorText
            hoverBackground: root.withAlpha(root.colorOverlay, 0.85)
            focusColor: root.colorAccent
            onClicked: sddm.reboot()
        }
        IconButton {
            visible: sddm.canPowerOff
            glyph: root.glyphShutdown
            label: tr.shutdown
            fontFamily: root.fontFamily
            foreground: root.colorText
            hoverBackground: root.withAlpha(root.colorOverlay, 0.85)
            focusColor: root.colorAccent
            onClicked: sddm.powerOff()
        }
    }

    // One timer for the clock and the date.
    QtObject {
        id: timeSource
        property date now: new Date()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: timeSource.now = new Date()
    }

    Component.onCompleted: {
        if (root.hasUsers)
            passwordField.forceActiveFocus();
        else
            usernameField.forceActiveFocus();
    }
}
