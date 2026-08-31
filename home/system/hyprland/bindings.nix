{
  pkgs,
  lib,
  config,
  scripts,
  ...
}: let
  colors = config.lib.stylix.colors;
  border-size = config.theme.border-size;

  mkMenu = menu: let
    configFile = pkgs.writeText "config.yaml" (
      lib.generators.toYAML {} {
        anchor = "top";
        border = "#${colors.base0D}EE";
        border_width = border-size;
        background = "#${colors.base01}FF";
        color = "#${colors.base05}";
        margin_top = 0;
        rows_per_column = 5;
        inherit menu;
      }
    );
  in
    pkgs.writeShellScriptBin "menu" ''
      if ${pkgs.procps}/bin/pkill -x wlr-which-key; then
        exit 0
      fi
      exec ${lib.getExe pkgs.wlr-which-key} ${configFile}
    '';

  tofi-drun-toggle = pkgs.writeShellScriptBin "tofi-drun-toggle" ''
    if ${pkgs.procps}/bin/pkill -x tofi-drun; then
      exit 0
    fi
    exec ${pkgs.tofi}/bin/tofi-drun
  '';

  screenshotRegion = pkgs.writeShellScriptBin "screenshot-region-edit" ''
    mkdir -p "$HOME/Pictures/Screenshots"
    file="$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
    ${pkgs.hyprshot}/bin/hyprshot -m region --raw | ${pkgs.satty}/bin/satty --filename - --output-filename "$file"
  '';

  screenshotOutput = pkgs.writeShellScriptBin "screenshot-output-edit" ''
    mkdir -p "$HOME/Pictures/Screenshots"
    file="$HOME/Pictures/Screenshots/screenshot-$(date +%Y%m%d-%H%M%S).png"
    ${pkgs.hyprshot}/bin/hyprshot -m output --raw | ${pkgs.satty}/bin/satty --filename - --output-filename "$file"
  '';

  recordingToggle = pkgs.writeShellScriptBin "recording-toggle" ''
    mkdir -p "$HOME/Videos/Recordings"
    if ${pkgs.procps}/bin/pgrep -x wf-recorder >/dev/null; then
      ${pkgs.procps}/bin/pkill -INT -x wf-recorder
      exit 0
    fi
    geometry="$(${pkgs.slurp}/bin/slurp)" || exit 0
    file="$HOME/Videos/Recordings/recording-$(date +%Y%m%d-%H%M%S).mp4"
    ${pkgs.wf-recorder}/bin/wf-recorder -g "$geometry" -f "$file" >/dev/null 2>&1 &
  '';
in {
  home.packages = [pkgs.slurp];

  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    "$shiftMod" = "SUPER_SHIFT";

    bind =
      [
        (
          "$shiftMod, A, exec, "
          + lib.getExe (mkMenu [
            {key = "a"; desc = "Proton Authenticator"; cmd = "env WEBKIT_DISABLE_COMPOSITING_MODE=1 ${pkgs.proton-authenticator}/bin/proton-authenticator";}
            {key = "p"; desc = "Proton Pass"; cmd = "${pkgs.proton-pass}/bin/proton-pass";}
            {key = "v"; desc = "Proton VPN"; cmd = "${pkgs.proton-vpn}/bin/protonvpn-app";}
            {key = "c"; desc = "Proton Calendar"; cmd = "${config.programs.helium.package}/bin/helium 'https://calendar.proton.me/'";}
            {key = "m"; desc = "Proton Mail"; cmd = "${config.programs.helium.package}/bin/helium 'https://mail.proton.me/'";}
            {key = "o"; desc = "Obsidian"; cmd = "${pkgs.obsidian}/bin/obsidian";}
            {key = "s"; desc = "Signal"; cmd = "${pkgs.signal-desktop}/bin/signal-desktop";}
            {key = "t"; desc = "TickTick"; cmd = "${pkgs.ticktick}/bin/ticktick";}
            {key = "b"; desc = "Helium"; cmd = "${config.programs.helium.package}/bin/helium";}
            {key = "i"; desc = "Helium (Incognito)"; cmd = "${config.programs.helium.package}/bin/helium --incognito";}
          ])
        )
        "$mod,B, exec, uwsm app -- ${config.programs.helium.package}/bin/helium"
        (
          "$mod, X, exec, "
          + lib.getExe (mkMenu [
            {key = "l"; desc = "Lock"; cmd = "${pkgs.hyprlock}/bin/hyprlock";}
            {key = "s"; desc = "Suspend"; cmd = "systemctl suspend";}
            {key = "r"; desc = "Reboot"; cmd = "systemctl reboot";}
            {key = "p"; desc = "Power Off"; cmd = "systemctl poweroff";}
          ])
        )
        "$mod,RETURN, exec, ${pkgs.ghostty}/bin/ghostty +new-window"
        "$mod,E, exec, ${pkgs.ghostty}/bin/ghostty +new-window -e elio"
        "$mod, SPACE, exec, ${lib.getExe tofi-drun-toggle}"
        "$mod, N, exec, ${pkgs.swaynotificationcenter}/bin/swaync-client -t"
        "$mod,Q, killactive,"
        "$mod,F, fullscreen"
        "$shiftMod,F, togglefloating,"
        "$shiftMod, SPACE, exec, ${scripts.focus-toggle}/bin/focus-toggle"
        "$mod,H, movefocus, l"
        "$mod,J, movefocus, d"
        "$mod,K, movefocus, u"
        "$mod,L, movefocus, r"
        "$shiftMod,H, focusmonitor, -1"
        "$shiftMod,J, layoutmsg, removemaster"
        "$shiftMod,K, layoutmsg, addmaster"
        "$shiftMod,L, focusmonitor, 1"
        "$mod, S, togglespecialworkspace, scratch"
        "$shiftMod, S, movetoworkspace, special:scratch"
        ", Print, exec, ${lib.getExe screenshotRegion}"
        "$shiftMod, Print, exec, ${lib.getExe screenshotOutput}"
        "$mod, Print, exec, ${lib.getExe recordingToggle}"
      ]
      ++ (builtins.concatLists (
        builtins.genList (
          i: let ws = i + 1; in [
            "$mod,code:1${toString i}, workspace, ${toString ws}"
            "$mod SHIFT,code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      ));

    bindm = [
      "$mod,mouse:272, movewindow"
      "$mod,R, resizewindow"
    ];

    bindl = [
      ", XF86MonBrightnessUp, exec, ${scripts.bright-up}/bin/bright-up"
      ", XF86MonBrightnessDown, exec, ${scripts.bright-down}/bin/bright-down"
      ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
      ", XF86AudioPause, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
      ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
      ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
      ", XF86AudioStop, exec, ${pkgs.playerctl}/bin/playerctl stop"
      ", XF86AudioMute, exec, ${scripts.vol-mute}/bin/vol-mute"
      ", XF86AudioRaiseVolume, exec, ${scripts.vol-up}/bin/vol-up"
      ", XF86AudioLowerVolume, exec, ${scripts.vol-down}/bin/vol-down"
      ", XF86AudioMicMute, exec, ${scripts.mic-mute}/bin/mic-mute"
    ];
  };
}
