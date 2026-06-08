{ config, lib, ... }:

{
    programs.hyprlock = {
        enable = true;
        settings = {
            general = {
                disable_loading_bar = true;
                hide_cursor         = true;
                no_fade_in          = false;
            };

            # `path = screenshot` blurs the live screen contents — that's the
            # "blur of the screen" look. Bump blur_passes / blur_size for more.
            background = [{
                monitor      = "";
                path         = "screenshot";
                blur_passes  = 4;
                blur_size    = 8;
                noise        = "0.0117";
                contrast     = 0.9;
                brightness   = 0.7;
                vibrancy     = 0.2;
                vibrancy_darkness = 0.0;
            }];

            input-field = [{
                monitor          = "";
                size             = "300, 50";
                outline_thickness = 2;
                inner_color      = "rgba(30, 30, 46, 0.6)";  # base00
                outer_color      = "rgba(137, 180, 250, 0.9)"; # base0D
                check_color      = "rgba(249, 226, 175, 0.9)"; # base0A
                fail_color       = "rgba(243, 139, 168, 0.9)"; # base08
                font_color       = "rgba(205, 214, 244, 1)";   # base05
                fade_on_empty    = false;
                rounding         = 12;
                placeholder_text = ''<i>password</i>'';
                fail_text        = "$PAMFAIL";
                dots_spacing     = 0.3;
                position         = "0, -120";
                halign           = "center";
                valign           = "center";
            }];

            label = [
                # Big clock, top-right.
                {
                    monitor     = "";
                    text        = "$TIME";
                    font_size   = 92;
                    font_family = "JetBrains Mono";
                    color       = "rgba(205, 214, 244, 0.95)";
                    position    = "-40, -40";
                    halign      = "right";
                    valign      = "top";
                }
                # Date below the clock, refreshed once a minute.
                {
                    monitor     = "";
                    text        = ''cmd[update:60000] date +"%A, %d %B %Y"'';
                    font_size   = 22;
                    font_family = "JetBrains Mono";
                    color       = "rgba(166, 227, 161, 0.85)";  # base0B
                    position    = "-40, -150";
                    halign      = "right";
                    valign      = "top";
                }

                # ---- RSS headlines ----
                # Re-evaluated every 5 min by hyprlock; `qs-rss` itself caches
                # its selection for 15 min so the three rows stay coherent.
                # Pango markup OK (the qs-rss `line` subcommand emits it).
                {
                    monitor     = "";
                    text        = "cmd[update:300000] qs-rss line 0";
                    font_size   = 14;
                    font_family = "JetBrains Mono";
                    color       = "rgba(205, 214, 244, 0.85)";
                    position    = "40, 120";
                    halign      = "left";
                    valign      = "bottom";
                }
                {
                    monitor     = "";
                    text        = "cmd[update:300000] qs-rss line 1";
                    font_size   = 14;
                    font_family = "JetBrains Mono";
                    color       = "rgba(205, 214, 244, 0.85)";
                    position    = "40, 90";
                    halign      = "left";
                    valign      = "bottom";
                }
                {
                    monitor     = "";
                    text        = "cmd[update:300000] qs-rss line 2";
                    font_size   = 14;
                    font_family = "JetBrains Mono";
                    color       = "rgba(205, 214, 244, 0.85)";
                    position    = "40, 60";
                    halign      = "left";
                    valign      = "bottom";
                }
            ];
        };
    };
}
