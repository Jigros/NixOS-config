# Source: https://github.com/Dylouwu/MyNixy/blob/main/nixos/steam.nix
{
  config,
  pkgs,
  ...
}: {
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  environment.systemPackages = with pkgs; [
    mangohud
    protonup-ng
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/${config.var.username}/.steam/root/compatibilitytools.d";
  };

  programs.gamemode.enable = true;
}

# DP-3 gaming monitor: 1920x1080 @ 144 Hz.
# Recommended per-game launch option:
# LD_PRELOAD="" gamescope -W 1920 -H 1080 -r 144 -f -- %command%
# LD_PRELOAD="" avoids the long-session slowdown seen with some games.
