// One PanelWindow instance per monitor. shell.qml creates these inside a
// Variants over Quickshell.screens and feeds in the theme via properties.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    id: bar

    // ---- injected from shell.qml ----
    property var palette
    property int barHeight: 36
    property int barMargin: 6
    property int radius: 12
    property string fontFamily: "JetBrains Mono"

    // ---- popup references (passed from shell.qml) ----
    property var powerMenu
    property var audioMixer
    property var networkPicker
    property var launcher

    // ---- panel geometry ----
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: barHeight + barMargin * 2
    exclusiveZone: barHeight + barMargin
    color: "transparent"

    // ---- one-shot launchers (clicked → start, exits on its own) ----
    Process { id: launcherProc; command: ["wofi", "-GiIS", "drun"] }

    // ===========================================================
    //  Network status — polls every 10s. Output of the script is one
    //  of: "ethernet|<iface>" / "wifi|<ssid>" / "disconnected".
    // ===========================================================
    property string networkType: "disconnected"
    property string networkLabel: ""

    Process {
        id: networkProc
        command: ["sh", "-c",
            "for d in /sys/class/net/*; do " +
            "  i=$(basename \"$d\"); " +
            "  [ \"$i\" = lo ] && continue; " +
            "  if [ ! -d \"$d/wireless\" ] && [ \"$(cat \"$d/operstate\" 2>/dev/null)\" = up ]; then " +
            "    echo \"ethernet|$i\"; exit 0; " +
            "  fi; " +
            "done; " +
            "for d in /sys/class/net/*; do " +
            "  i=$(basename \"$d\"); " +
            "  if [ -d \"$d/wireless\" ]; then " +
            "    ssid=$(iwctl station \"$i\" show 2>/dev/null | " +
            "           sed -e 's/\\x1b\\[[0-9;]*m//g' | " +
            "           awk -F': +' '/Connected network/{print $2; exit}'); " +
            "    ssid=$(echo \"$ssid\" | sed 's/^ *//;s/ *$//'); " +
            "    if [ -n \"$ssid\" ]; then echo \"wifi|$ssid\"; exit 0; fi; " +
            "  fi; " +
            "done; " +
            "echo disconnected"
        ]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split("|");
                bar.networkType = parts[0] || "disconnected";
                bar.networkLabel = parts[1] || "";
            }
        }
    }
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: networkProc.running = true
    }

    // ===========================================================
    //  Tailscale — polls `tailscale status --json` every 10s.
    //  jq squashes the response to one line: "<state> <peer_count>"
    //  so QML doesn't have to parse JSON itself.
    // ===========================================================
    property string tailscaleState: "Stopped"
    property int tailscalePeers: 0

    Process {
        id: tailscaleProc
        command: ["sh", "-c",
            "tailscale status --json 2>/dev/null | " +
            "jq -r '\"\\(.BackendState // \"Stopped\") \\((.Peer // {}) | to_entries | map(select(.value.Online)) | length)\"'"
        ]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(" ");
                bar.tailscaleState = parts[0] || "Stopped";
                bar.tailscalePeers = parseInt(parts[1] || "0", 10);
            }
        }
    }
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: tailscaleProc.running = true
    }

    // ===========================================================
    //  Docker — hidden when daemon is off (matches enableOnBoot=false).
    //  Emits "running total" or empty when systemctl says inactive.
    // ===========================================================
    property int dockerRunning: 0
    property int dockerTotal: 0
    property bool dockerActive: false

    Process {
        id: dockerProc
        command: ["sh", "-c",
            "if systemctl is-active --quiet docker.service; then " +
            "  echo \"$(docker ps -q 2>/dev/null | wc -l) $(docker ps -aq 2>/dev/null | wc -l) 1\"; " +
            "else echo '0 0 0'; fi"
        ]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.trim().split(" ");
                bar.dockerRunning = parseInt(parts[0] || "0", 10);
                bar.dockerTotal   = parseInt(parts[1] || "0", 10);
                bar.dockerActive  = (parts[2] || "0") === "1";
            }
        }
    }
    Timer {
        interval: 10000; running: true; repeat: true
        onTriggered: dockerProc.running = true
    }

    // ===========================================================
    //  Pipewire — binding the default sink makes audio.volume/muted
    //  valid. Tracker drops to [] when the sink disappears.
    // ===========================================================
    PwObjectTracker {
        objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : []
    }

    // ===========================================================
    //  Bar background — translucent pill spanning the bar width
    // ===========================================================
    Rectangle {
        id: panel
        anchors.fill: parent
        anchors.margins: bar.barMargin
        radius: bar.radius
        // 0xd9 ≈ 0.85 alpha over base00
        color: "#d9" + bar.palette.base00.toString().substring(1)
        border.width: 0

        // ---- LEFT: launcher + workspaces -----------------------
        // Anchors on Row children are ignored, so every item is height: 26
        // for visual alignment; Repeater children inherit the Row's flow.
        Row {
            id: leftRow
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 8
            spacing: 6

            // Launcher pill
            Rectangle {
                width: 36; height: 26
                radius: 8
                color: launcherMA.containsMouse
                    ? bar.palette.base0D
                    : "#99" + bar.palette.base02.toString().substring(1)
                Text {
                    anchors.centerIn: parent
                    text: ""  // nf-fa-rocket (font-awesome)
                    font.family: bar.fontFamily
                    font.pixelSize: 14
                    color: launcherMA.containsMouse ? bar.palette.base00 : bar.palette.base05
                }
                MouseArea {
                    id: launcherMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.launcher.toggle()
                }
            }

            // Workspaces — clickable pills, one per existing Hyprland workspace.
            // TODO: waybar used persistent-workspaces 1..10; replicate by
            // padding the Repeater with dummy entries if you miss that.
            Repeater {
                model: Hyprland.workspaces
                delegate: Rectangle {
                    required property HyprlandWorkspace modelData
                    width: 28; height: 26
                    radius: 6
                    color: modelData.focused
                        ? bar.palette.base0D
                        : modelData.active
                            ? "#8089b4fa"
                            : wsMA.containsMouse
                                ? "#4089b4fa"
                                : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: modelData.id
                        font.family: bar.fontFamily
                        font.pixelSize: 12
                        color: modelData.focused ? bar.palette.base00 : bar.palette.base05
                    }
                    MouseArea {
                        id: wsMA
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace " + modelData.id)
                    }
                }
            }
        }

        // ---- CENTER: clock -------------------------------------
        Item {
            anchors.centerIn: parent
            implicitWidth: clock.implicitWidth
            implicitHeight: clock.implicitHeight

            property date now: new Date()
            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: parent.now = new Date()
            }

            Text {
                id: clock
                anchors.centerIn: parent
                text: Qt.formatDateTime(parent.now, "ddd dd MMM   hh:mm")
                font.family: bar.fontFamily
                font.pixelSize: 13
                font.bold: true
                color: bar.palette.base05
            }
        }

        // ---- RIGHT: volume, battery, tailscale, docker, power --
        // Text children get height: 26 + verticalAlignment so they line up
        // with the pills inside the Row's default top-alignment.
        Row {
            id: rightRow
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 8
            spacing: 10

            // -- Volume (Pipewire default sink) — click opens mixer --
            Text {
                height: 26
                verticalAlignment: Text.AlignVCenter
                font.family: bar.fontFamily
                font.pixelSize: 12
                color: bar.palette.base05
                text: {
                    const sink = Pipewire.defaultAudioSink;
                    if (!sink || !sink.audio) return "";
                    //  = nf-fa-volume-off,  = nf-fa-volume-up
                    if (sink.audio.muted) return " muted";
                    return " " + Math.round(sink.audio.volume * 100) + "%";
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.audioMixer.toggle()
                }
            }

            // -- Network -- click opens wifi picker --
            Text {
                height: 26
                verticalAlignment: Text.AlignVCenter
                font.family: bar.fontFamily
                font.pixelSize: 12
                color: bar.networkType === "disconnected"
                    ? bar.palette.base03
                    : bar.palette.base05
                text: {
                    //  nf-fa-sitemap,  wifi,  chain-broken
                    if (bar.networkType === "ethernet") return " " + bar.networkLabel;
                    if (bar.networkType === "wifi")     return " " + bar.networkLabel;
                    return "";
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.networkPicker.toggle()
                }
            }

            // -- Battery (UPower display device) --
            Text {
                height: 26
                verticalAlignment: Text.AlignVCenter
                font.family: bar.fontFamily
                font.pixelSize: 12
                visible: UPower.displayDevice && UPower.displayDevice.ready
                color: {
                    const d = UPower.displayDevice;
                    if (!d) return bar.palette.base05;
                    if (d.percentage <= 15 && d.state === UPowerDeviceState.Discharging)
                        return bar.palette.base08;
                    return bar.palette.base05;
                }
                text: {
                    const d = UPower.displayDevice;
                    if (!d) return "";
                    const pct = Math.round(d.percentage);
                    const charging = d.state === UPowerDeviceState.Charging
                                  || d.state === UPowerDeviceState.FullyCharged;
                    //  = nf-fa-bolt,  = nf-fa-battery-full
                    return (charging ? " " : " ") + pct + "%";
                }
            }

            // -- Tailscale --
            Text {
                height: 26
                verticalAlignment: Text.AlignVCenter
                font.family: bar.fontFamily
                font.pixelSize: 12
                color: bar.tailscaleState === "Running"
                    ? bar.palette.base0B
                    : bar.tailscaleState === "Stopped" || bar.tailscaleState === "NoState"
                        ? bar.palette.base03
                        : bar.palette.base09
                text: bar.tailscaleState === "Running"
                    ? "󰖂 " + bar.tailscalePeers
                    : "󰖂"
            }

            // -- Docker (hidden when daemon is inactive) --
            Text {
                height: 26
                verticalAlignment: Text.AlignVCenter
                font.family: bar.fontFamily
                font.pixelSize: 12
                visible: bar.dockerActive
                color: bar.dockerRunning > 0 ? bar.palette.base0D : bar.palette.base03
                text: "󰡨 " + bar.dockerRunning
            }

            // -- Power pill --
            Rectangle {
                width: 36; height: 26
                radius: 8
                color: powerMA.containsMouse
                    ? bar.palette.base0D
                    : "#99" + bar.palette.base02.toString().substring(1)
                Text {
                    anchors.centerIn: parent
                    text: "⏻"
                    font.family: bar.fontFamily
                    font.pixelSize: 14
                    color: powerMA.containsMouse ? bar.palette.base00 : bar.palette.base05
                }
                MouseArea {
                    id: powerMA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: bar.powerMenu.toggle()
                }
            }
        }
    }
}
