{ inputs, settings, ... }:

{
    imports = [ ../packages/system/hyprland.nix ];
    home-manager.users.${settings.username}.imports = [
        inputs.illogical-flake.homeManagerModules.default
        ../packages/user/illogical-overrides.nix
    ];
}
