{ config, ... }:

{
    programs.hyprlock = {
        enable = true;
        settings = {
            general = {
                disable_loading_bar = true;
                hide_cursor         = true;
                no_fade_in          = false;
            };

            background = [{
                path        = "screenshot";
                blur_passes = 3;
                blur_size   = 8;
            }];

            label = [
                {
                    text      = ''cmd[update:1000] echo "$(date +"%H:%M")"'';
                    font_size = 90;
                    position  = "0, 200";
                    halign    = "center";
                    valign    = "center";
                }
                {
                    text      = ''cmd[update:60000] echo "$(date +"%A, %d %B")"'';
                    font_size = 22;
                    position  = "0, 100";
                    halign    = "center";
                    valign    = "center";
                }
            ];

            input-field = [{
                size              = "300, 50";
                position          = "0, -80";
                halign            = "center";
                valign            = "center";
                outline_thickness = 2;
                fade_on_empty     = true;
                placeholder_text  = "<i>Password...</i>";
            }];
        };
    };
}
