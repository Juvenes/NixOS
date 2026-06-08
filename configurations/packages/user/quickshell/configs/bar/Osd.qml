// D7 — Bottom-center OSD for volume + brightness changes. Triggered
// via `qs ipc call osd showVolume|showBrightness` from Hyprland's
// XF86Audio* / XF86MonBrightness* keybinds (see keybindings.nix).
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    property string mode: "volume"   // "volume" | "brightness"
    property int level: 0            // 0..100
    property bool muted: false
    property string label: ""

    function showVolume() {
        mode = "volume";
        const sink = Pipewire.defaultAudioSink;
        if (sink && sink.audio) {
            level = Math.round(sink.audio.volume * 100);
            muted = sink.audio.muted;
        }
        label = muted ? "Muted" : (level + "%");
        visible = true;
        hideTimer.restart();
    }

    function showBrightness() {
        mode = "brightness";
        brightnessProc.running = true;
    }

    Process {
        id: brightnessProc
        command: ["sh", "-c", "echo $(( $(brightnessctl g) * 100 / $(brightnessctl m) ))"]
        stdout: SplitParser {
            onRead: line => {
                root.level = parseInt(line.trim(), 10) || 0;
                root.muted = false;
                root.label = root.level + "%";
                root.visible = true;
                hideTimer.restart();
            }
        }
    }

    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    Timer {
        id: hideTimer
        interval: 1500; repeat: false
        onTriggered: root.visible = false
    }

    visible: false
    anchors { bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    color: "transparent"
    implicitHeight: 100

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 50
        width: 280
        height: 64
        radius: 14
        color: "#e61e1e2e"
        border.color: root.palette.base02
        border.width: 1

        Row {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 14

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.mode === "volume"
                    ? (root.muted ? "" : "")
                    : ""
                font.family: root.fontFamily
                font.pixelSize: 22
                color: root.palette.base05
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                width: parent.width - 60

                Text {
                    text: root.label
                    font.family: root.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: root.palette.base05
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: root.palette.base02

                    Rectangle {
                        width: parent.width * (Math.max(0, Math.min(100, root.level)) / 100)
                        height: parent.height
                        radius: parent.radius
                        color: root.muted ? root.palette.base03 : root.palette.base0D
                    }
                }
            }
        }
    }
}
