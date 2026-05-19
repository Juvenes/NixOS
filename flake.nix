{
    description = "A Nix centralized for Personnal use";

    inputs = {
        # NixPkgs
        nixpkgs.url = "nixpkgs/nixos-25.11";
        nixpkgs-unstable.url = "nixpkgs/nixos-unstable";

        # Home manager
        home-manager.url = "github:nix-community/home-manager/release-25.11";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
	    # NixVim
	    nixvim.url = "github:nix-community/nixvim/nixos-25.11";
	    nixvim.inputs.nixpkgs.follows = "nixpkgs";
    
        # Stylix
        stylix.url = "github:danth/stylix/release-25.11";
    };

    outputs = inputs@{ nixpkgs, ... }: 
        let
            settings = import ./settings.nix;
        in {
            nixosConfigurations = {
                # Configurations
                roole-nixos-laptop = nixpkgs.lib.nixosSystem {
                    system = settings.system;
                    specialArgs = { inherit inputs; inherit settings; };
                    modules = [ ./configurations/nixos.nix ./configurations ];
                };
           };
        };
}
