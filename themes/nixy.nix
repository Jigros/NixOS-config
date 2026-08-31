{
  lib,
  pkgs,
  config,
  ...
}: {
  options.theme = lib.mkOption {
    type = lib.types.attrs;
    default = {
      rounding = 20;
      bar-height = 36;
      gaps-in = 8;
      gaps-out = 8 * 2;
      active-opacity = 0.96;
      inactive-opacity = 0.92;
      blur = false;
      border-size = 2;
      animation-speed = "medium"; # "very-fast" | "fast" | "medium" | "slow"
    };
    description = "Theme configuration options";
  };

  config.stylix = {
    enable = true;

    # See https://tinted-theming.github.io/tinted-gallery/ for more schemes
    base16Scheme = {
      base00 = "0A0A0C";
      base01 = "110F12";
      base02 = "2D2A36";
      base03 = "514D63";
      base04 = "8E8AA0";
      base05 = "C2BED6";
      base06 = "D8D5EA";
      base07 = "EAE7F7";
      base08 = "E07080";
      base09 = "D49070";
      base0A = "C4B060";
      base0B = "80B880";
      base0C = "70B8C0";
      base0D = "9E97F8";
      base0E = "C090E8";
      base0F = "D080A0";
    };

    cursor = {
      name = "BreezeX-RosePine-Linux";
      package = pkgs.rose-pine-cursor;
      size = 20;
    };

    fonts = {
      monospace = {
        package = pkgs.maple-mono.NF;
        name = "Maple Mono NF";
      };
      sansSerif = {
        package = pkgs.rubik;
        name = "Rubik";
      };
      serif = config.stylix.fonts.sansSerif;
      emoji = {
        package = pkgs.noto-fonts-color-emoji;
        name = "Noto Color Emoji";
      };
      sizes = {
        applications = 13;
        desktop = 13;
        popups = 13;
        terminal = 13;
      };
    };

    polarity = "dark";
    image = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/anotherhadi/awesome-wallpapers/main/wallpapers/another-one.png";
      sha256 = "sha256-bKke8RNz6qNxHSfLbU5xVVkG3tbFZW1sFjLB1hltcoI=";
    };
  };
}
