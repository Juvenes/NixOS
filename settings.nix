{
    username = "roole";
    hostname = "roole-nixos-laptop";
    system = "x86_64-linux";
    flake-directory = "~/.dotfiles";

    # Github @TODO
    gh-username = null;
    gh-email = null;

    # Desktop environment
    desktop = ./configurations/desktop-environment/hyprland.nix;
    theme = ./configurations/themes/mocha.nix;
}
