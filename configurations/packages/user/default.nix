{ config, inputs, pkgs, settings, ... }:

{
    imports = [ inputs.home-manager.nixosModules.home-manager ];

    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "old";
	    extraSpecialArgs = { inherit inputs; inherit settings; hostname = config.networking.hostName; };
        sharedModules = [
            ./git.nix
            ./bash.nix
            ./fish.nix
            ./starship.nix
	        ./nixvim.nix
            ./programming.nix
            ./lab.nix
            ./kitty.nix
            ./gpg.nix
            ./ssh.nix
            ./firefox.nix
            settings.theme
            {
                home.stateVersion = "25.11";
                home.packages = with pkgs; [
                    gimp
                    onlyoffice-desktopeditors
                    vlc
                    feh
                    unstable.vesktop
                    ungoogled-chromium
                    playerctl
                    brightnessctl
                    zip
                    unzip
                    dust
                    tree
                    jq
                    eza
                    wofi
                    wlogout
                ];
            }
        ];
    };
}
