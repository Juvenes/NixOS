{ pkgs, ... }:

{
    home.packages = with pkgs; [
        python313
        python313Packages.requests
    ];

    programs.yarn.enable = true;
}
