// D6 — Quick scratch note. Pops a multi-line text field. Ctrl+Enter or
// the Save button appends to ~/notes/scratch.md prefixed with a UTC
// timestamp. Esc dismisses without saving.
import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily
    property string draft: ""

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            draft = "";
            visible = true;
        }
    }

    function save() {
        if (!draft.trim()) {
            visible = false;
            return;
        }
        // Pass note content as $1 to avoid any shell injection on the body.
        noteProc.command = [
            "sh", "-c",
            "mkdir -p \"$HOME/notes\" && " +
            "printf '\\n## %s\\n%s\\n' \"$(date '+%Y-%m-%d %H:%M')\" \"$1\" " +
            ">> \"$HOME/notes/scratch.md\"",
            "_", draft
        ];
        noteProc.running = true;
        draft = "";
        visible = false;
    }

    Process { id: noteProc; command: [] }

    visible: false
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    color: "transparent"

    onVisibleChanged: if (visible) noteInput.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.centerIn: parent
        width: 560
        height: 320
        radius: 16
        color: "#f01e1e2e"
        border.color: root.palette.base02
        border.width: 1

        MouseArea { anchors.fill: parent; preventStealing: true; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Row {
                width: parent.width
                spacing: 10

                Text {
                    text: ""  // nf-fa-pencil-square
                    font.family: root.fontFamily
                    font.pixelSize: 16
                    color: root.palette.base05
                }
                Text {
                    text: "Quick note — appends to ~/notes/scratch.md"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    color: root.palette.base04
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 80
                radius: 8
                color: root.palette.base02

                Flickable {
                    anchors.fill: parent
                    anchors.margins: 10
                    clip: true
                    contentWidth: noteInput.width
                    contentHeight: noteInput.height

                    TextEdit {
                        id: noteInput
                        width: parent.width
                        wrapMode: TextEdit.Wrap
                        text: root.draft
                        onTextChanged: root.draft = text
                        font.family: root.fontFamily
                        font.pixelSize: 13
                        color: root.palette.base05
                        selectByMouse: true
                        focus: true

                        Keys.onEscapePressed: root.visible = false
                        Keys.onPressed: (event) => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                                && (event.modifiers & Qt.ControlModifier)) {
                                event.accepted = true;
                                root.save();
                            }
                        }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                spacing: 10

                Rectangle {
                    width: 100; height: 30
                    radius: 6
                    color: cancelMa.containsMouse ? root.palette.base03 : root.palette.base02
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel (Esc)"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        color: root.palette.base05
                    }
                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.visible = false
                    }
                }

                Rectangle {
                    width: 130; height: 30
                    radius: 6
                    color: saveMa.containsMouse ? root.palette.base0B : root.palette.base0D
                    Text {
                        anchors.centerIn: parent
                        text: "Save (Ctrl+Enter)"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: root.palette.base00
                    }
                    MouseArea {
                        id: saveMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.save()
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
