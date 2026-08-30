{...}: let
  bookmarkList =
    (import ../helium/bookmarks/general.nix)
    ++ (import ../helium/bookmarks/tools.nix)
    ++ (import ../helium/bookmarks/entertainment.nix)
    ++ (import ../helium/bookmarks/infosec.nix)
    ++ (import ../helium/bookmarks/other.nix)
    ++ (import ../helium/bookmarks/jack.nix);

  withoutStartpage = items:
    builtins.filter (item: !(item ? name && item.name == "Startpage Config")) (
      map (
        item:
          if item ? bookmarks
          then item // {bookmarks = withoutStartpage item.bookmarks;}
          else item
      )
      items
    );

  toChromium = items:
    map (item:
      if item ? url
      then {inherit (item) name url;}
      else {
        name = item.name;
        children = toChromium item.bookmarks;
      })
    items;
in {
  stylix.targets.chromium.enable = false;

  programs.chromium = {
    enable = true;

    extensions = [
      "nngceckbaplhbijlkkkjpmoihodkdojp" # Bitwarden
      "mdjildafknihdffpkfmmpnpoiajfjnjd" # Consent-O-Matic
      "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger
    ];

    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "https://search.brave.com/search?q={searchTerms}";
    defaultSearchProviderSuggestURL = "https://search.brave.com/api/suggest?q={searchTerms}";

    extraOpts = {
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

      DnsOverHttpsMode = "secure";
      DnsOverHttpsTemplates = "https://dns.quad9.net/dns-query";

      DefaultSearchProviderName = "Brave Search";

      HomepageIsNewTabPage = true;
      ShowHomeButton = false;
      RestoreOnStartup = 5;

      BookmarkBarEnabled = false;
      ManagedBookmarks = toChromium (withoutStartpage bookmarkList);

      BraveShieldsAdControl = 2;
      BraveShieldsTrackersBlocked = 1;
      BraveShieldsHttpsEverywhere = 1;
      BraveRewardsDisabled = 1;
      BraveWalletDisabled = 1;
      BraveVPNDisabled = 1;
      BraveAIChatEnabled = 0;
      BravePlaylistEnabled = 0;
      BraveWebDiscoveryEnabled = 0;
      BraveStatsPingEnabled = 0;
    };
  };
}
