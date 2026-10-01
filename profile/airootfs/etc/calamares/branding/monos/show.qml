/* monOS installation slideshow (Calamares 3.4, Qt 6, slideshow API 2).
 * The color properties are rewritten by branding/tools/gen-themes.py from
 * branding/palette/monos.toml; background.jpg comes from install-branding.sh. */

import QtQuick
import calamares.slideshow 1.0

Presentation
{
    id: presentation

    readonly property color bgColor: "#0B0D12"
    readonly property color accentColor: "#3D8BFF"
    readonly property color fgColor: "#E6E9EF"

    function nextSlide() {
        presentation.goToNextSlide();
    }

    Timer {
        id: advanceTimer
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: nextSlide()
    }

    // Background: brand color, the monOS Nebula wallpaper and a dark veil
    // that keeps the text readable (fg on veil >= 7:1).
    Rectangle {
        anchors.fill: parent
        color: presentation.bgColor
        z: -3
    }
    Image {
        anchors.fill: parent
        source: "background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        z: -2
    }
    Rectangle {
        anchors.fill: parent
        color: presentation.bgColor
        opacity: 0.55
        z: -1
    }

    Slide {
        Image {
            id: logo1
            source: "logo.png"
            width: 180; height: 180
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.08
        }
        Text {
            id: title1
            anchors.top: logo1.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Welcome to monOS"
            color: presentation.accentColor
            font.pixelSize: 30
            font.bold: true
        }
        Text {
            anchors.top: title1.bottom
            anchors.topMargin: 12
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: presentation.fgColor
            font.pixelSize: 16
            text: "A rolling, Arch Linux based system with KDE Plasma on Wayland. "
                + "Sit back while monOS is copied to your disk."
        }
    }

    Slide {
        Text {
            id: title2
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.2
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Built for developers"
            color: presentation.accentColor
            font.pixelSize: 30
            font.bold: true
        }
        Text {
            anchors.top: title2.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: presentation.fgColor
            font.pixelSize: 16
            text: "Git, compilers, Python, Node.js, Go, Rust, Java, Docker, VS Code, "
                + "Neovim and a modern terminal toolbox are ready out of the box. "
                + "The AUR is one command away with yay."
        }
    }

    Slide {
        Text {
            id: title3
            anchors.top: parent.top
            anchors.topMargin: parent.height * 0.2
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Snapshots keep you safe"
            color: presentation.accentColor
            font.pixelSize: 30
            font.bold: true
        }
        Text {
            anchors.top: title3.bottom
            anchors.topMargin: 16
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: presentation.fgColor
            font.pixelSize: 16
            text: "On btrfs, every package update takes a snapshot automatically. "
                + "If something breaks, pick an earlier snapshot from the GRUB menu "
                + "and roll back."
        }
    }

    function onActivate() {
        presentation.currentSlide = 0;
    }

    function onLeave() {
    }
}
