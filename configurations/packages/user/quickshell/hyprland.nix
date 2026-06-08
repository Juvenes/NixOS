{ ... }:

{
    imports = [ ./default.nix ];

    # Bind quickshell's user service to the Hyprland graphical session so it
    # starts/stops with the compositor instead of generic graphical-session.target.
    programs.quickshell.systemd.target = "hyprland-session.target";
}
