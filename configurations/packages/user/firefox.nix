{ config, lib, pkgs, ... }:

let
    profileName = "main";
in {
    programs.firefox = {
        enable = true;
        package = pkgs.unstable.firefox;

        policies = {
            DisableFirefoxStudies = true;
            DisableTelemetry = true;
            EnableTrackingProtection = {
                Value = true;
                Cryptomining = true;
                Fingerprinting = true;
                EmailTracking = true;
            };

            DisablePocket = true;
            DisableFirefoxAccounts = true;
            DNSOverHTTPS = {
                Enabled = true;
                ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
                Fallback = true;
            };

            ExtensionSettings = {
                "uBlock0@raymondhill.net" = {
                    installation_mode = "normal_installed";
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
                };

                "firefox@ghostery.com" = {
                    installation_mode = "normal_installed";
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/firefox@ghostery.com/latest.xpi";
                };

                # Bitwarden
                "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
                    installation_mode = "normal_installed";
                    install_url = "https://addons.mozilla.org/firefox/downloads/latest/{446900e4-71c2-419f-a6a7-df9c091e268b}/latest.xpi";
                };

                # Spell checking (French)
                "fr-dicollecte@dictionaries.addons.mozilla.org" = {
                    installation_mode = "normal_installed";
                    install_url = "https://addons.mozilla.org/firefox/downloads/file/3581786/dictionnaire_francais1-7.0b.xpi";
                };
                
            };

            FirefoxHome = {
                TopSites = false;
                SponsoredTopSites = false;
                Highlights = false;
                Pocket = false;
                SponsoredPocket = false;
            };

            FirefoxSuggest = {
                SponsoredSuggestions = false;
                ImproveSuggest = false;
            };

            NoDefaultBookmarks = true;
            OfferToSaveLoginsDefault = false;
            AutofillAddressEnabled = false;
            AutofillCreditCardEnabled = false;

            Cookies = {
                Behavior = "limit-foreign";
            };

            settings = {
                "browser.search.region" = "GB";
                "general.useragent.override" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:129.0) Gecko/20100101 Firefox/129.";
                "privacy.fingerprintingProtection" = true;
                "spellchecker.dictionary" = "fr,en-US,";
                "network.captive-portal-service.enabled" = false;

                # Enable DRM (/!\ Maintained by Google)
                "media.eme.enabled" = true;
            };
        };
    };
}
