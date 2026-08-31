{...}: {
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
      ShowHomeButton = false;
      BookmarkBarEnabled = false;

      # Helium's module documents plain Chrome Web Store extension IDs here.
      # Avoid custom update URLs so Helium can manage installation itself.
      ExtensionInstallForcelist = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        "mnjggcdmjocbbbhaepdhchncahnbgone" # SponsorBlock
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # uBlock Origin
        "mdjildafknihdffpkfmmpnpoiajfjnjd" # Consent-O-Matic
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
        "eimadpbcbfnmbkopoojfekhnkhdbieeh" # Dark Reader
      ];
    };
  };
}
