{ ... }:

{
    programs.starship = {
        enable = true;
        enableFishIntegration = true;
        enableBashIntegration = true;

        settings = {
            add_newline = false;
            format = "$cmd_duration $directory$git_branch\n  $character";

            character = {
                success_symbol = "[ ](bold fg:243)";
                error_symbol   = "[ ](bold fg:244)";
            };

            git_branch = {
                symbol = "󰘬";
                format = " 󰜥 [](bold fg:252)[$symbol $branch(:$remote_branch)](fg:235 bg:252)[ ](bold fg:252)";
            };

            directory = {
                style  = "bg:255 fg:240";
                format = "[](bold fg:255)[󰉋 → $path]($style)[](bold fg:255)";
            };

            cmd_duration = {
                min_time = 0;
                format   = "[](bold fg:252)[󰪢 $duration](bold bg:252 fg:235)[](bold fg:252)";
            };
        };
    };
}
