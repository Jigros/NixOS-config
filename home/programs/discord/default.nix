# Discord is a popular chat application.
{
  inputs,
  lib,
  ...
}: {
  imports = [inputs.nixcord.homeModules.nixcord];

  stylix.targets = {
    nixcord.enable = false;
    vencord.enable = false;
  };

  programs.nixcord = {
    enable = true;
    discord.vencord.enable = true;
    discord.krisp.enable = true;

    config = {
      frameless = true;
      enabledThemes = lib.mkForce [];
      enabledThemeLinks = lib.mkForce [];

      plugins = {
        betterRoleContext.enable = true;
        biggerStreamPreview.enable = true;
        callTimer.enable = true;
        characterCounter.enable = true;
        clearUrls.enable = true;
        crashHandler.enable = true;
        expressionCloner.enable = true;
        fakeNitro.enable = true;
        fakeProfileThemes.enable = true;
        fixImagesQuality.enable = true;
        fixSpotifyEmbeds.enable = true;
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        #friendsSince.enable = true;
        fullSearchContext.enable = true;
        gameActivityToggle.enable = true;
        gifPaste.enable = true;
        imageZoom.enable = true;
        memberCount.enable = true;
        messageLogger.enable = true;
        newGuildSettings.enable = true;
        platformIndicators.enable = true;
        relationshipNotifier.enable = true;
        serverInfo.enable = true;
        showHiddenChannels.enable = true;
        showHiddenThings.enable = true;
        spotifyCrack.enable = true;
        translate.enable = true;
        unlockedAvatarZoom.enable = true;
        usrbg.enable = true;
        validReply.enable = true;
        validUser.enable = true;
        viewIcons.enable = true;
        volumeBooster.enable = true;
        youtubeAdblock.enable = true;
      };
    };
  };
}
