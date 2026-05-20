{ lib, ... }:

{
    programs.waybar = {
        enable = true;
        systemd.enable = true;

        style = lib.mkAfter ''
            #workspaces button.empty {
                opacity: 0.5;
            }

            #workspaces button.active {
                color: @base0B;
                opacity: 1;
            }

            label.module, box.module, .modules-right {
                padding: 0 10px;
            }

            .modules-right .module {
                margin: 0 10px;
            }

            #clock {
                font-size: 17px;
            }

            #temperature.critical,
            #network.disconnected,
            #disk.critical,
            #battery.critical,
            #memory.critical {
                font-weight: bold;
                color: @base08;
            }

            #custom-launcher,
            #custom-cmd,
            #custom-power {
                padding: 0 12px;
                margin: 4px 6px;
                border-radius: 8px;
                background-color: alpha(@base02, 0.6);
                font-size: 16px;
            }

            #custom-launcher:hover,
            #custom-cmd:hover,
            #custom-power:hover {
                background-color: @base0D;
                color: @base00;
            }
        '';

        settings.main = {
            layer = "top";

            # Bar

            modules-left = ["custom/launcher" "custom/cmd"];
            modules-center = ["bluetooth" "clock" "custom/microphone"];
            modules-right = ["wireplumber" "temperature" "memory" "disk" "cpu" "network" "battery" "custom/power"];

            "custom/launcher" = {
                format   = "";
                tooltip  = false;
                on-click = "wofi -GiIS drun";
            };

            "custom/cmd" = {
                format         = "";
                tooltip-format = "Run command";
                on-click       = "wofi --show run";
            };

            "custom/power" = {
                format   = "⏻";
                tooltip  = false;
                on-click = "wlogout";
            };


            wireplumber = {
                format = "{volume}% ";
                format-muted = "";
                max-volume = 150;
                scroll-step = 0.5;
            };

            temperature = {
                format = "{temperatureC}°C ";
                format-critical = "{temperatureC}°C ";
                critical-threshold = 80;
            };

            network = {
                interval = 30;
                format = "?";
                format-disconnected = "";
                format-wifi = "";
                format-ethernet = "󰈀";
                tooltip-format = "{ipaddr}";
            };

            bluetooth = {
                format = "";
                format-on = "";
                format-connected = "󰂱";
            };

            memory = {
                interval = 5;
                format = "{}% ";
                max-length = 10;
                states = {
                    critical = 85;
                };
            };

            cpu = {
                interval = 5;
                format = "{}% ";
                max-length = 10;
            };

            battery = {
                interval = 10;
                format = "{capacity}% {icon}";
                format-charging = "{capacity}% {icon}";
                format-icons = {
                    discharging = ["" "" "" "" ""];
                    charging = "";
                    full = "";
                };
                states = {
                    critical = 15;
                    full = 100;
                };
            };

            clock = {
                format-alt = "{:%a, %d. %b  %H:%M}";
            };
        };
    };
}
