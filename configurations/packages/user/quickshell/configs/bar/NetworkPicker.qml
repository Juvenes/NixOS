// D3 — iwd-backed wifi picker. Shows scanned networks, click to
// connect. v1 limitation: first-time connection to a secured unknown
// network needs to be done on the CLI (`iwctl station <iface>
// connect <ssid>`) so iwd can store credentials. After that, clicking
// here will reconnect using the saved profile.
import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    property string iface: ""
    property string currentSsid: ""
    property var networks: []  // [{ name, security, signal, connected }, ...]

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            visible = true;
            refresh();
        }
    }

    function refresh() {
        networks = [];
        detectIfaceProc.running = true;
    }

    // Step 1: find the wifi iface name.
    Process {
        id: detectIfaceProc
        command: ["sh", "-c",
            "iwctl device list 2>/dev/null | " +
            "awk 'NR>3 && $1!~/^-/ && $1!=\"\" {print $1; exit}'"
        ]
        stdout: SplitParser {
            onRead: line => {
                root.iface = line.trim();
                if (root.iface) {
                    scanProc.command = ["iwctl", "station", root.iface, "scan"];
                    scanProc.running = true;
                }
            }
        }
    }

    // Step 2: trigger scan (fire-and-forget; iwd updates its cache).
    Process { id: scanProc; command: [] }
    Connections {
        target: scanProc
        function onRunningChanged() {
            if (!scanProc.running && root.iface) {
                // Give iwd a beat to publish results, then list.
                listTimer.start();
            }
        }
    }
    Timer {
        id: listTimer
        interval: 600; repeat: false
        onTriggered: {
            getNetsProc.command = ["sh", "-c",
                "iwctl station \"$1\" get-networks 2>/dev/null | " +
                "sed -e 's/\\x1b\\[[0-9;]*m//g' | " +
                "awk 'NR>4 && NF>=3 { " +
                "  connected=0; if($1==\"*\"||$1==\">\"){connected=1; $1=\"\"} " +
                "  n=NF; sec=$(n-1); sig=$n; name=\"\"; " +
                "  for(i=1;i<=n-2;i++) name=name (i>1?\" \":\"\") $i; " +
                "  gsub(/^[ \\t]+|[ \\t]+$/,\"\",name); " +
                "  if(name!=\"\") printf \"%s|%s|%s|%d\\n\", name, sec, sig, connected " +
                "}'",
                "_", root.iface
            ];
            getNetsProc.running = true;
        }
    }

    // Step 3: collect network rows.
    Process {
        id: getNetsProc
        command: []
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split("|");
                if (parts.length < 4) return;
                const entry = {
                    name: parts[0],
                    security: parts[1],
                    signal: parts[2],
                    connected: parts[3] === "1",
                };
                if (entry.connected) root.currentSsid = entry.name;
                const next = root.networks.slice();
                next.push(entry);
                root.networks = next;
            }
        }
    }

    Process { id: connectProc; command: [] }

    function connect(ssid) {
        connectProc.command = ["iwctl", "station", root.iface, "connect", ssid];
        connectProc.running = true;
        // Optimistic UI: refresh after a short delay so the
        // connected-row marker moves.
        reRefresh.start();
    }
    Timer { id: reRefresh; interval: 2500; repeat: false; onTriggered: root.refresh() }

    visible: false
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    color: "transparent"

    onVisibleChanged: if (visible) forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 50
        width: 420
        height: 460
        radius: 14
        color: "#f01e1e2e"
        border.color: root.palette.base02
        border.width: 1

        MouseArea { anchors.fill: parent; preventStealing: true; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: "Wi-Fi"
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: root.palette.base05
                }

                Item { width: parent.width - 100; height: 1 }

                Rectangle {
                    width: 70; height: 22
                    radius: 6
                    color: rescanMa.containsMouse ? root.palette.base0D : root.palette.base02
                    Text {
                        anchors.centerIn: parent
                        text: "Rescan"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        color: rescanMa.containsMouse ? root.palette.base00 : root.palette.base05
                    }
                    MouseArea {
                        id: rescanMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh()
                    }
                }
            }

            Text {
                visible: root.iface === ""
                text: "(no wifi device)"
                font.family: root.fontFamily
                font.pixelSize: 11
                color: root.palette.base04
            }

            ListView {
                width: parent.width
                height: parent.height - 60
                clip: true
                model: root.networks
                spacing: 4

                delegate: Rectangle {
                    required property var modelData
                    width: ListView.view.width
                    height: 44
                    radius: 8
                    color: ma.containsMouse
                        ? root.palette.base02
                        : modelData.connected
                            ? "#404075a5"
                            : root.palette.base01

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 70

                            Text {
                                text: modelData.name + (modelData.connected ? "   (connected)" : "")
                                font.family: root.fontFamily
                                font.pixelSize: 12
                                color: root.palette.base05
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.security + "  " + modelData.signal
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.palette.base04
                            }
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!modelData.connected) root.connect(modelData.name);
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
