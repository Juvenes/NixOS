// D5 — Clipboard history backed by cliphist. Lists recent entries,
// filterable by substring. Click or Enter pastes the entry back into
// the clipboard via wl-copy. Esc dismisses.
import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    property string query: ""
    property var entries: []   // [{ id: string, preview: string }, ...]
    property var filtered: []

    function refresh() {
        listProc.running = true;
    }

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            query = "";
            entries = [];
            filtered = [];
            visible = true;
            refresh();
        }
    }

    function copyEntry(id) {
        copyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "_", id];
        copyProc.running = true;
        visible = false;
    }

    function applyFilter() {
        const q = query.toLowerCase();
        if (!q) { filtered = entries; return; }
        filtered = entries.filter(e => e.preview.toLowerCase().includes(q));
    }

    onQueryChanged: applyFilter()

    // Collects `cliphist list` output. Each line: "<id>\t<preview>".
    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: line => {
                const tab = line.indexOf("\t");
                if (tab < 1) return;
                const id = line.substring(0, tab);
                const preview = line.substring(tab + 1);
                const next = root.entries.slice();
                next.push({ id, preview });
                root.entries = next;
                root.applyFilter();
            }
        }
    }
    Process { id: copyProc; command: [] }

    visible: false
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    color: "transparent"

    onVisibleChanged: if (visible) searchInput.forceActiveFocus()

    MouseArea {
        anchors.fill: parent
        onClicked: root.visible = false
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 120
        width: 640
        height: 460
        radius: 16
        color: "#f01e1e2e"
        border.color: root.palette.base02
        border.width: 1

        MouseArea { anchors.fill: parent; preventStealing: true; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                width: parent.width
                height: 40
                radius: 8
                color: root.palette.base02

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ""  // nf-fa-clipboard
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        color: root.palette.base04
                    }

                    TextInput {
                        id: searchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 40
                        text: root.query
                        onTextChanged: root.query = text
                        font.family: root.fontFamily
                        font.pixelSize: 14
                        color: root.palette.base05
                        selectByMouse: true
                        focus: true

                        Keys.onEscapePressed: root.visible = false
                        Keys.onReturnPressed: {
                            if (root.filtered.length > 0)
                                root.copyEntry(root.filtered[0].id);
                        }
                        Keys.onEnterPressed: Keys.returnPressed(event)
                    }
                }
            }

            ListView {
                id: results
                width: parent.width
                height: parent.height - 52
                clip: true
                model: root.filtered
                spacing: 2

                delegate: Rectangle {
                    required property var modelData
                    width: results.width
                    height: 36
                    radius: 6
                    color: ma.containsMouse
                        ? root.palette.base02
                        : "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        text: modelData.preview
                        font.family: root.fontFamily
                        font.pixelSize: 12
                        color: root.palette.base05
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.copyEntry(modelData.id)
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
