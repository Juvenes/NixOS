// RSS reader popup. Pulls articles from `qs-rss pick`, renders as
// cards on the right side of the screen. Left-click opens the link
// in firefox AND dismisses (so it doesn't show up again).
// Right-click dismisses without opening. Esc / 'r' / click-out
// dismiss the whole popup.
import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    property var articles: []

    function toggle() {
        if (visible) {
            visible = false;
        } else {
            visible = true;
            fetchProc.running = true;
        }
    }

    function forceRefresh() {
        refreshProc.running = true;
        // Slight delay before refetching so qs-rss has written the new selection.
        refetchTimer.restart();
    }

    function consume(article, openLink) {
        dismissProc.command = ["qs-rss", "dismiss", article.id];
        dismissProc.running = true;
        if (openLink && article.link) {
            openProc.command = ["firefox", "--new-tab", article.link];
            openProc.running = true;
        }
        // Drop from the visible list immediately.
        articles = articles.filter(a => a.id !== article.id);
    }

    // Polls qs-rss for the current selection.
    Process {
        id: fetchProc
        command: ["qs-rss", "pick", "--n", "8", "--format", "json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.articles = JSON.parse(this.text || "[]");
                } catch (e) {
                    root.articles = [];
                }
            }
        }
    }

    Process { id: refreshProc; command: ["qs-rss", "refresh"] }
    Process { id: dismissProc; command: [] }
    Process { id: openProc;    command: [] }

    Timer {
        id: refetchTimer
        interval: 400; repeat: false
        onTriggered: fetchProc.running = true
    }

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
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.rightMargin: 16
        anchors.topMargin: 56     // clear the bar
        anchors.bottomMargin: 56
        width: 440
        radius: 16
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
                    text: "RSS"
                    font.family: root.fontFamily
                    font.pixelSize: 14
                    font.bold: true
                    color: root.palette.base05
                }
                Text {
                    text: "left-click = open + dismiss · right-click = dismiss"
                    font.family: root.fontFamily
                    font.pixelSize: 10
                    color: root.palette.base04
                }
                Item { width: 1; height: 1 }

                Rectangle {
                    width: 70; height: 22
                    radius: 6
                    color: refreshMa.containsMouse ? root.palette.base0D : root.palette.base02
                    Text {
                        anchors.centerIn: parent
                        text: "Reroll"
                        font.family: root.fontFamily
                        font.pixelSize: 11
                        color: refreshMa.containsMouse ? root.palette.base00 : root.palette.base05
                    }
                    MouseArea {
                        id: refreshMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.forceRefresh()
                    }
                }
            }

            Text {
                visible: root.articles.length === 0
                text: "(no articles — qs-rss may still be fetching, or your\n" +
                      " ~/.config/quickshell/rss-feeds.txt is empty)"
                font.family: root.fontFamily
                font.pixelSize: 11
                color: root.palette.base04
            }

            ListView {
                id: results
                width: parent.width
                height: parent.height - 50
                clip: true
                model: root.articles
                spacing: 8

                delegate: Rectangle {
                    required property var modelData
                    width: results.width
                    height: cardCol.implicitHeight + 16
                    radius: 10
                    color: ma.containsMouse ? root.palette.base02 : root.palette.base01

                    Column {
                        id: cardCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 6

                        // Source pill
                        Rectangle {
                            width: srcLabel.implicitWidth + 14
                            height: 18
                            radius: 9
                            color: root.palette.base02
                            Text {
                                id: srcLabel
                                anchors.centerIn: parent
                                text: modelData.source
                                font.family: root.fontFamily
                                font.pixelSize: 10
                                color: root.palette.base0D
                            }
                        }

                        Text {
                            width: parent.width
                            text: modelData.title
                            font.family: root.fontFamily
                            font.pixelSize: 13
                            color: root.palette.base05
                            wrapMode: Text.WordWrap
                        }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onClicked: (mouse) => {
                            root.consume(modelData, mouse.button === Qt.LeftButton);
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
    Keys.onPressed: (event) => {
        if (event.text === "r") { root.forceRefresh(); event.accepted = true; }
    }
}
