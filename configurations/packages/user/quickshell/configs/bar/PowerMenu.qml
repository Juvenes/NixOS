// D4 — Centered overlay replacing wlogout. Buttons: Lock / Logout /
// Suspend / Reboot / Shutdown. Click outside or Esc to dismiss.
import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    function toggle() { visible = !visible }

    visible: false
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    color: "transparent"

    onVisibleChanged: if (visible) forceActiveFocus()

    Process { id: lockProc;     command: ["hyprlock"] }
    Process { id: logoutProc;   command: ["hyprctl", "dispatch", "exit"] }
    Process { id: suspendProc;  command: ["systemctl", "suspend"] }
    Process { id: rebootProc;   command: ["systemctl", "reboot"] }
    Process { id: shutdownProc; command: ["systemctl", "poweroff"] }

    // Click outside the card dismisses.
    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 540
        height: 180
        radius: 16
        color: "#f01e1e2e"  // base00 ~94% alpha
        border.color: root.palette.base02
        border.width: 1

        // Swallow clicks so they don't bubble to the outer dismiss area.
        MouseArea { anchors.fill: parent; preventStealing: true; onClicked: {} }

        Row {
            anchors.centerIn: parent
            spacing: 16

            Repeater {
                model: [
                    { icon: "", label: "Lock",     action: () => lockProc.running     = true },
                    { icon: "", label: "Logout",   action: () => logoutProc.running   = true },
                    { icon: "", label: "Suspend",  action: () => suspendProc.running  = true },
                    { icon: "", label: "Reboot",   action: () => rebootProc.running   = true },
                    { icon: "⏻", label: "Shutdown", action: () => shutdownProc.running = true },
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 90; height: 110
                    radius: 12
                    color: ma.containsMouse ? root.palette.base0D : root.palette.base02

                    Column {
                        anchors.centerIn: parent
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.family: root.fontFamily
                            font.pixelSize: 30
                            color: ma.containsMouse ? root.palette.base00 : root.palette.base05
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.label
                            font.family: root.fontFamily
                            font.pixelSize: 11
                            color: ma.containsMouse ? root.palette.base00 : root.palette.base05
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false;
                            modelData.action();
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
