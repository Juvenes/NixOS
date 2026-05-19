{ pkgs, ... }:

{
    imports = [
        ./hardware/work-hardware-configuration.nix
        ./packages/system/fingerprint.nix
    ];

    networking.hostName = "roole-nixos-laptop";
    boot.kernelParams = [ "iommu=soft" ];

    environment.systemPackages = [
        pkgs.unstable.ferdium
    ];

    # TLP Power management
    services.tlp.enable = true;
}
