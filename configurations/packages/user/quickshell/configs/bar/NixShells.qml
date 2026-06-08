// Grid of pre-defined nix-shell environments. Click → opens a kitty
// running `nix-shell -p <pkgs>`. Edit the `shells` model below to add
// more — each entry needs a name, icon (single glyph), and the list of
// nixpkgs attrs to pull in.
import Quickshell
import Quickshell.Io
import QtQuick

PanelWindow {
    id: root
    property var palette
    property string fontFamily

    // Edit me! Each entry: { name, icon, pkgs (array of nixpkgs attr names) }.
    readonly property var shells: [
        { name: "Python",   icon: "", pkgs: ["python313", "python313Packages.ipython", "python313Packages.requests"] },
        { name: "Rust",     icon: "", pkgs: ["rustc", "cargo", "rust-analyzer"] },
        { name: "Node",     icon: "", pkgs: ["nodejs", "yarn", "pnpm"] },
        { name: "Go",       icon: "", pkgs: ["go", "gopls"] },
        { name: "Lua",      icon: "", pkgs: ["lua5_4", "lua-language-server"] },
        { name: "K8s",      icon: "", pkgs: ["kubectl", "kubernetes-helm", "k9s", "kubectx"] },
        { name: "AWS",      icon: "", pkgs: ["awscli2", "aws-vault"] },
        { name: "GCP",      icon: "", pkgs: ["google-cloud-sdk"] },
        { name: "Postgres", icon: "", pkgs: ["postgresql_16"] },
        { name: "Redis",    icon: "", pkgs: ["redis"] },
        { name: "TS/Web",   icon: "", pkgs: ["nodejs", "typescript", "vite"] },
        { name: "Recon",    icon: "", pkgs: ["nmap", "ffuf", "gobuster", "whatweb"] },
    ]

    function toggle() { visible = !visible }

    function launch(shell) {
        kittyProc.command = ["kitty", "--title", "nix-shell: " + shell.name,
                             "nix-shell", "-p"].concat(shell.pkgs);
        kittyProc.running = true;
    }

    Process { id: kittyProc; command: [] }

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
        anchors.centerIn: parent
        width: 560
        height: 360
        radius: 16
        color: "#f01e1e2e"
        border.color: root.palette.base02
        border.width: 1

        MouseArea { anchors.fill: parent; preventStealing: true; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            Text {
                text: "Nix shells"
                font.family: root.fontFamily
                font.pixelSize: 14
                font.bold: true
                color: root.palette.base05
            }

            GridView {
                width: parent.width
                height: parent.height - 30
                cellWidth: 130
                cellHeight: 80
                model: root.shells
                interactive: false

                delegate: Rectangle {
                    required property var modelData
                    width: 120; height: 70
                    radius: 10
                    color: ma.containsMouse ? root.palette.base0D : root.palette.base02

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon
                            font.family: root.fontFamily
                            font.pixelSize: 22
                            color: ma.containsMouse ? root.palette.base00 : root.palette.base05
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
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
                            root.launch(modelData);
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.visible = false
}
