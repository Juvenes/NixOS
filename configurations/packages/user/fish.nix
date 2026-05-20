{ pkgs, ... }:

{
    programs.fish = {
        enable = true;

        interactiveShellInit = ''
            set fish_greeting
        '';

        shellAliases = {
            clear  = "printf '\\033[2J\\033[3J\\033[1;1H'";
            ls     = "eza --icons";
            dot    = "git --git-dir=$HOME/.dotfiles --work-tree=$HOME";
            envpip = "source ./.venv/bin/activate.fish";
        };

        functions = {
            agented = ''
                eval (ssh-agent -c)
                ssh-add ~/.ssh/id_ed25519
            '';
        };
    };
}
