{ config, pkgs, ... }:

{
    programs.kitty = {
        enable = true;
        shellIntegration.enableFishIntegration = true;

        settings = {
            confirm_os_window_close = 0;
            cursor_shape            = "beam";
            cursor_trail            = 1;
            enable_audio_bell       = false;
            window_padding_width    = 22;
            shell                   = "fish";
        };
    };
}
