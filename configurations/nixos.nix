{ pkgs, settings, ... }:

{
    imports = [
        ./hardware/work-hardware-configuration.nix
        ./packages/system/fingerprint.nix
    ];

    networking.hostName = settings.hostname;
    boot.kernelParams = [ "iommu=soft" ];

    environment.systemPackages = [
        pkgs.unstable.ferdium
    ];

    # TLP Power management
    services.tlp.enable = true;
}
