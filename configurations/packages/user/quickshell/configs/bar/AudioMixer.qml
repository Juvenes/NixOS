// D2 — Per-app Pipewire mixer. Lists every output stream (isStream &&
// !isSink) with a volume slider + mute toggle. Closes on click outside
// or Esc.
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    property var streams: []

    function rebuild() {
        const out = [];
        const all = Pipewire.nodes;
        const n = all.values ? all.values.length : 0;
        for (let i = 0; i < n; i++) {
            const node = all.values[i];
            if (node && node.isStream && !node.isSink && node.audio) {
                out.push(node);
            }
        }
        streams = out;
    }

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            rebuild();
            visible = true;
        }
    }

    Component.onCompleted: rebuild()
    Connections {
        target: Pipewire.nodes
        function onValuesChanged() { root.rebuild() }
    }

    // Bind every stream so audio.volume / audio.muted become readable
    // AND writable for our slider.
    PwObjectTracker { objects: root.streams }

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
        height: Math.min(480, 80 + root.streams.length * 70 + 60)
        radius: 14
        color: "#f01e1e2e"
        border.color: root.palette.base02
        border.width: 1

        MouseArea { anchors.fill: parent; preventStealing: true; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Text {
                text: "Audio mixer"
                font.family: root.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: root.palette.base05
            }

            Text {
                visible: root.streams.length === 0
                text: "(no audio streams playing)"
                font.family: root.fontFamily
                font.pixelSize: 11
                color: root.palette.base04
            }

            Column {
                width: parent.width
                spacing: 10

                Repeater {
                    model: root.streams
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 64
                        radius: 8
                        color: root.palette.base01

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            Row {
                                width: parent.width
                                spacing: 8

                                Text {
                                    width: parent.width - muteBtn.width - 8
                                    text: {
                                        const p = modelData.properties || {};
                                        return p["application.name"]
                                            || p["media.name"]
                                            || modelData.name
                                            || "(unknown)";
                                    }
                                    font.family: root.fontFamily
                                    font.pixelSize: 12
                                    color: root.palette.base05
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    id: muteBtn
                                    width: 30; height: 18
                                    radius: 6
                                    color: modelData.audio && modelData.audio.muted
                                        ? root.palette.base08
                                        : root.palette.base02
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.audio && modelData.audio.muted ? "M" : "S"
                                        font.family: root.fontFamily
                                        font.pixelSize: 10
                                        color: root.palette.base05
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.audio)
                                                modelData.audio.muted = !modelData.audio.muted;
                                        }
                                    }
                                }
                            }

                            // Click-to-set volume bar.
                            Rectangle {
                                id: track
                                width: parent.width
                                height: 14
                                radius: 7
                                color: root.palette.base02

                                Rectangle {
                                    width: track.width * (modelData.audio ? Math.min(1, modelData.audio.volume) : 0)
                                    height: parent.height
                                    radius: parent.radius
                                    color: modelData.audio && modelData.audio.muted
                                        ? root.palette.base03
                                        : root.palette.base0D
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onPressed: (mouse) => {
                                        if (modelData.audio)
                                            modelData.audio.volume = Math.max(0, Math.min(1, mouse.x / width));
                                    }
                                    onPositionChanged: (mouse) => {
                                        if (pressed && modelData.audio)
                                            modelData.audio.volume = Math.max(0, Math.min(1, mouse.x / width));
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
