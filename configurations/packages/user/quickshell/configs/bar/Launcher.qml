// O3 — App launcher replacing wofi. Uses Quickshell.DesktopEntries to
// enumerate .desktop files, simple substring filter, Enter launches
// first match, Esc/click outside dismisses.
import Quickshell
import Quickshell.Widgets
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    property string query: ""
    property var filtered: []

    function refresh() {
        const q = query.toLowerCase();
        const out = [];
        const apps = DesktopEntries.applications.values;
        for (let i = 0; i < apps.length; i++) {
            const e = apps[i];
            if (!q
                || e.name.toLowerCase().includes(q)
                || (e.comment || "").toLowerCase().includes(q)) {
                out.push(e);
            }
        }
        // Sort: prefix matches first, then substring matches, alphabetical.
        out.sort((a, b) => {
            const aPrefix = a.name.toLowerCase().startsWith(q) ? 0 : 1;
            const bPrefix = b.name.toLowerCase().startsWith(q) ? 0 : 1;
            if (aPrefix !== bPrefix) return aPrefix - bPrefix;
            return a.name.localeCompare(b.name);
        });
        filtered = out;
    }

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            query = "";
            refresh();
            visible = true;
        }
    }

    visible: false
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    focusable: true
    color: "transparent"

    onVisibleChanged: if (visible) searchInput.forceActiveFocus()
    onQueryChanged: refresh()

    Component.onCompleted: refresh()

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

            // ---- search row ----
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
                        text: ""  // nf-fa-search
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
                        clip: true
                        focus: true

                        Keys.onEscapePressed: root.visible = false
                        Keys.onReturnPressed: {
                            if (root.filtered.length > 0) {
                                root.visible = false;
                                root.filtered[0].execute();
                            }
                        }
                        Keys.onEnterPressed: Keys.returnPressed(event)
                    }
                }
            }

            // ---- results ----
            ListView {
                id: results
                width: parent.width
                height: parent.height - 52
                clip: true
                model: root.filtered
                spacing: 2

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: results.width
                    height: 44
                    radius: 6
                    color: ma.containsMouse
                        ? root.palette.base02
                        : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        IconImage {
                            anchors.verticalCenter: parent.verticalCenter
                            implicitSize: 28
                            source: modelData.icon ? "image://icon/" + modelData.icon : ""
                            visible: modelData.icon !== ""
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 50
                            spacing: 2
                            Text {
                                text: modelData.name
                                font.family: root.fontFamily
                                font.pixelSize: 13
                                color: root.palette.base05
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: modelData.comment || ""
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.palette.base04
                                elide: Text.ElideRight
                                width: parent.width
                                visible: modelData.comment !== ""
                            }
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.visible = false;
                            modelData.execute();
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
