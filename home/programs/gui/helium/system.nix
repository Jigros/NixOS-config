{...}: let
  bookmarkList =
    (import ./bookmarks/general.nix)
    ++ (import ./bookmarks/tools.nix)
    ++ (import ./bookmarks/entertainment.nix)
    ++ (import ./bookmarks/infosec.nix)
    ++ (import ./bookmarks/other.nix)
    ++ (import ./bookmarks/jack.nix);

  toChromium = items:
    map (item:
      if item ? url
      then {inherit (item) name url;}
      else {
        name = item.name;
        children = toChromium item.bookmarks;
      })
    items;

  chromeWebStore = "https://clients2.google.com/service/update2/crx";
in {
  stylix.targets.chromium.enable = false;

  programs.helium = {
    enable = true;

    policies = {
      BrowserSignin = 0;
      SyncDisabled = true;
      SigninAllowed = false;
      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;
      SafeBrowsingEnabled = false;
      MetricsReportingEnabled = false;
      SpellCheckServiceEnabled = false;
      DefaultCookiesSetting = 1;
      DefaultGeolocationSetting = 2;
      DefaultNotificationsSetting = 2;
      DefaultPopupsSetting = 2;
      DefaultBrowserSettingEnabled = false;
      DeveloperToolsAvailability = 1;
      DnsOverHttpsMode = "automatic";
      DnsOverHttpsTemplates = "https://dns.quad9.net/dns-query";
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "Startpage";
      DefaultSearchProviderSearchURL = "https://www.startpage.com/do/search?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://www.startpage.com/do/suggest?q={searchTerms}";
      NewTabPageLocation = "http://127.0.0.1:8888";
      HomepageIsNewTabPage = false;
      HomepageLocation = "http://127.0.0.1:8888";
      ShowHomeButton = false;
      RestoreOnStartup = 4;
      BookmarkBarEnabled = false;
      ManagedBookmarks = toChromium bookmarkList;

      # Explicit Chrome Web Store update URL is required reliably by Chromium's
      # force-install policy on Linux/Chromium derivatives.
      ExtensionInstallForcelist = [
        "nngceckbaplhbijlkkkjpmoihodkdojp;${chromeWebStore}" # Bitwarden
        "mnjggcdmjocbbbhaepdhchncahnbgone;${chromeWebStore}" # SponsorBlock
        "cjpalhdlnbpafiamejdnhcphjbkeiagm;${chromeWebStore}" # uBlock Origin
        "mdjildafknihdffpkfmmpnpoiajfjnjd;${chromeWebStore}" # Consent-O-Matic
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp;${chromeWebStore}" # Privacy Badger
      ];
    };
  };
}
