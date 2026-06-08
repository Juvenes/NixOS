{ ... }:

{
    programs.quickshell = {
        enable = true;
        systemd.enable = true;

        # Each entry becomes ~/.config/quickshell/<name>/, and quickshell picks the
        # one named in `activeConfig`. Keeping the QML out of /nix/store-managed
        # paths inside the dir lets the QML tree reference siblings naturally.
        configs.bar = ./configs/bar;
        activeConfig = "bar";
    };
}
