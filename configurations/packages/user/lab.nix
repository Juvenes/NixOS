{ pkgs, ... }:

{
    home.packages = with pkgs; [
        kubectl
        nerdctl
        terraform
        ansible
        tailscale
        openvpn
    ];
}
