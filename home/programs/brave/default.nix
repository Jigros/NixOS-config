{
  pkgs,
  lib,
  ...
}: let
  braveFlags = [
    # Native Wayland can freeze Chromium-based browsers on very large paste operations.
    # XWayland keeps the browser usable while preserving the same profile/setup.
    "--ozone-platform=x11"
    "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
    "--disable-features=UseChromeOSDirectVideoDecoder,WaylandWpColorManagerV1"
    "--enable-accelerated-video-decode"
    "--enable-gpu-rasterization"
    "--use-gl=egl"
    "--no-default-browser-check"
    "--show-avatar-button=never"
  ];

  brave = pkgs.brave.override {
    commandLineArgs = lib.concatStringsSep " " braveFlags;
  };
in {
  home.packages = [brave];

  home.sessionVariables = {
    DEFAULT_BROWSER = "${brave}/bin/brave";
    BROWSER = "${brave}/bin/brave";
  };

  xdg.desktopEntries = {
    brave-private = {
      name = "Brave (Private window)";
      genericName = "Navigateur Web";
      exec = "${brave}/bin/brave --incognito %U";
      icon = "brave-browser";
      terminal = false;
      categories = ["Network" "WebBrowser"];
      mimeType = ["text/html" "text/xml" "application/xhtml+xml"];
    };

    brave-tor = {
      name = "Brave (Private window w/Tor)";
      genericName = "Navigateur Web";
      exec = "${brave}/bin/brave --tor %U";
      icon = "brave-browser";
      terminal = false;
      categories = ["Network" "WebBrowser"];
    };
  };
}
