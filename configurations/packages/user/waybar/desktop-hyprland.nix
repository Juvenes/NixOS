{ config, pkgs, ... }:

{
    imports = [ ./hyprland.nix ];

    programs.waybar.settings.main = {
        # Change the temperature zone used for CPU
        temperature.thermal-zone = 2;
    };

}
