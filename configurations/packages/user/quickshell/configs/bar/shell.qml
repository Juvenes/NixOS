// Quickshell entry point. Instantiates one Bar per monitor + a set of
// single-instance overlay popups + the IPC + GlobalShortcut wiring that
// lets Hyprland keybindings open them.
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root

    // Catppuccin Mocha — kept in sync with
    // ../../../stylix/styles/mocha.yaml. Bump both together.
    readonly property var palette: ({
        base00: "#1e1e2e", base01: "#181825", base02: "#313244",
        base03: "#45475a", base04: "#585b70", base05: "#cdd6f4",
        base06: "#f5e0dc", base07: "#b4befe",
        base08: "#f38ba8", base09: "#fab387", base0A: "#f9e2af",
        base0B: "#a6e3a1", base0C: "#94e2d5", base0D: "#89b4fa",
        base0E: "#cba6f7", base0F: "#f2cdcd",
    })

    readonly property int barHeight: 36
    readonly property int barMargin: 6
    readonly property int radius: 12
    readonly property string fontFamily: "JetBrains Mono"

    // ---- popups (hidden by default, shown via toggle()) ----
    PowerMenu     { id: powerMenu;     palette: root.palette; fontFamily: root.fontFamily }
    Launcher      { id: launcher;      palette: root.palette; fontFamily: root.fontFamily }
    NixShells     { id: nixShells;     palette: root.palette; fontFamily: root.fontFamily }
    QuickNote     { id: quickNote;     palette: root.palette; fontFamily: root.fontFamily }
    Clipboard     { id: clipboard;     palette: root.palette; fontFamily: root.fontFamily }
    AudioMixer    { id: audioMixer;    palette: root.palette; fontFamily: root.fontFamily }
    NetworkPicker { id: networkPicker; palette: root.palette; fontFamily: root.fontFamily }
    Osd           { id: osd;           palette: root.palette; fontFamily: root.fontFamily }
    RssReader     { id: rssReader;     palette: root.palette; fontFamily: root.fontFamily }

    // ---- Hyprland-side hotkeys (declared here, bound in keybindings.nix) ----
    GlobalShortcut { name: "launcher";  description: "App launcher"; onPressed: launcher.toggle() }
    GlobalShortcut { name: "note";      description: "Quick note";   onPressed: quickNote.toggle() }
    GlobalShortcut { name: "clipboard"; description: "Clipboard";    onPressed: clipboard.toggle() }
    GlobalShortcut { name: "nixshells"; description: "Nix shells";   onPressed: nixShells.toggle() }
    GlobalShortcut { name: "power";     description: "Power menu";   onPressed: powerMenu.toggle() }
    GlobalShortcut { name: "rss";       description: "RSS reader";   onPressed: rssReader.toggle() }

    // ---- CLI-callable hooks (qs ipc call <target> <fn>) ----
    // Used by volume/brightness keybindings to trigger the OSD after
    // adjusting the actual value via wpctl/brightnessctl.
    IpcHandler {
        target: "osd"
        function showVolume(): void { osd.showVolume() }
        function showBrightness(): void { osd.showBrightness() }
    }

    // Lets the bar pills open their drawers without each Bar instance
    // holding direct references to the popups.
    IpcHandler {
        target: "bar"
        function togglePower(): void { powerMenu.toggle() }
        function toggleAudio(): void { audioMixer.toggle() }
        function toggleNetwork(): void { networkPicker.toggle() }
    }

    // ---- one bar per monitor ----
    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
            palette: root.palette
            barHeight: root.barHeight
            barMargin: root.barMargin
            radius: root.radius
            fontFamily: root.fontFamily

            // Hand the popups in so click-to-open works without IPC.
            powerMenu: powerMenu
            audioMixer: audioMixer
            networkPicker: networkPicker
            launcher: launcher
        }
    }
}
