{ pkgs, ... }:

{
    # Forgive me Richard
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
        wget
        killall
        ntfs3g
        lsof
        usbutils
    ];

    fonts.packages = with pkgs; [
        material-icons
        font-awesome
    ];

    services.fwupd.enable = true;

    imports = [
        ./doas.nix
        ./git.nix
        ./docker.nix
        ./firewall.nix
        ./bluetooth.nix
        ./pipewire
        ./printer.nix
        ./tailscale.nix
    ];
}
